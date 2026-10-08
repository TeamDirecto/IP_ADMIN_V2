from __future__ import annotations

import argparse
import hashlib
import json
import secrets
from pathlib import Path

from backend.db import connect, init_db, json_dumps
from backend.app import utc_now


def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def add_node(db_path: str, node_name: str, token: str | None) -> None:
    token = token or secrets.token_urlsafe(32)
    now = utc_now()

    with connect(db_path) as conn:
        conn.execute(
            """
            INSERT INTO nodes(node_name, token_sha256, enabled, created_at, updated_at)
            VALUES (?, ?, 1, ?, ?)
            ON CONFLICT(node_name) DO UPDATE SET
                token_sha256=excluded.token_sha256,
                enabled=1,
                updated_at=excluded.updated_at
            """,
            (node_name, hash_token(token), now, now),
        )
        conn.commit()

    print(f"node={node_name}")
    print(f"token={token}")


def set_desired(db_path: str, node_name: str, generation: int, profile: str, state_file: str) -> None:
    state = json.loads(Path(state_file).read_text(encoding="utf-8"))
    canonical = json_dumps(state)
    desired_hash = hashlib.sha256(canonical.encode("utf-8")).hexdigest()
    now = utc_now()

    with connect(db_path) as conn:
        exists = conn.execute(
            "SELECT 1 FROM nodes WHERE node_name = ?",
            (node_name,),
        ).fetchone()
        if exists is None:
            raise SystemExit(f"node_not_found: {node_name}")

        current = conn.execute(
            "SELECT generation FROM desired_states WHERE node_name = ?",
            (node_name,),
        ).fetchone()
        if current is not None and generation <= current["generation"]:
            raise SystemExit(
                f"generation_must_increase: current={current['generation']} requested={generation}"
            )

        conn.execute(
            """
            INSERT INTO desired_states(
                node_name, generation, profile, state_json, desired_hash, updated_at
            )
            VALUES (?, ?, ?, ?, ?, ?)
            ON CONFLICT(node_name) DO UPDATE SET
                generation=excluded.generation,
                profile=excluded.profile,
                state_json=excluded.state_json,
                desired_hash=excluded.desired_hash,
                updated_at=excluded.updated_at
            """,
            (node_name, generation, profile, canonical, desired_hash, now),
        )
        conn.execute(
            """
            INSERT INTO audit_events(node_name, event_type, details_json, created_at)
            VALUES (?, 'DESIRED_UPDATED', ?, ?)
            """,
            (
                node_name,
                json_dumps(
                    {
                        "generation": generation,
                        "profile": profile,
                        "desired_hash": desired_hash,
                    }
                ),
                now,
            ),
        )
        conn.commit()

    print(f"node={node_name}")
    print(f"generation={generation}")
    print(f"desired_hash={desired_hash}")


def main() -> None:
    parser = argparse.ArgumentParser(description="IP_ADMIN_V2 backend management")
    parser.add_argument(
        "--db",
        default=None,
        help="SQLite database path; defaults to IP_ADMIN_DB_PATH or backend/instance/",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    init_cmd = sub.add_parser("init-db")
    init_cmd.set_defaults(action=lambda args: init_db(args.db))

    node_cmd = sub.add_parser("add-node")
    node_cmd.add_argument("node_name")
    node_cmd.add_argument("--token")
    node_cmd.set_defaults(
        action=lambda args: add_node(args.db, args.node_name, args.token)
    )

    desired_cmd = sub.add_parser("set-desired")
    desired_cmd.add_argument("node_name")
    desired_cmd.add_argument("--generation", type=int, required=True)
    desired_cmd.add_argument("--profile", required=True)
    desired_cmd.add_argument("--state-file", required=True)
    desired_cmd.set_defaults(
        action=lambda args: set_desired(
            args.db,
            args.node_name,
            args.generation,
            args.profile,
            args.state_file,
        )
    )

    args = parser.parse_args()
    args.action(args)


if __name__ == "__main__":
    main()
