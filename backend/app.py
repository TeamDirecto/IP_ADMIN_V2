from __future__ import annotations

import hmac
import os
from functools import wraps
from typing import Callable

from flask import Flask, current_app, jsonify, request

from backend.db import connect, init_db, json_dumps, json_loads
from backend.utils import token_hash, utc_now


HEALTH_STATES = {"SYNCED", "DRIFT", "STALE", "ERROR"}
ACTION_STATUSES = {"SUCCEEDED", "FAILED"}


def json_error(message: str, status: int):
    return jsonify({"error": message}), status


def require_node_auth(view: Callable):
    @wraps(view)
    def wrapped(node_name: str, *args, **kwargs):
        header = request.headers.get("Authorization", "")
        if not header.startswith("Bearer "):
            return json_error("unauthorized", 401)

        token = header[7:].strip()
        if not token:
            return json_error("unauthorized", 401)

        with connect(current_app.config["DB_PATH"]) as conn:
            row = conn.execute(
                "SELECT node_name, token_sha256, enabled FROM nodes WHERE node_name = ?",
                (node_name,),
            ).fetchone()

        if row is None or not row["enabled"]:
            return json_error("unauthorized", 401)

        if not hmac.compare_digest(token_hash(token), row["token_sha256"]):
            return json_error("unauthorized", 401)

        return view(node_name, *args, **kwargs)

    return wrapped


def create_app(db_path: str | None = None) -> Flask:
    app = Flask(__name__)
    app.config["DB_PATH"] = db_path or os.environ.get(
        "IP_ADMIN_DB_PATH",
        os.path.join(os.path.dirname(__file__), "instance", "ip_admin_v2.sqlite3"),
    )
    init_db(app.config["DB_PATH"])

    def db_connect():
        return connect(app.config["DB_PATH"])

    @app.get("/healthz")
    def healthz():
        return jsonify({"status": "ok", "service": "ip-admin-v2"})

    @app.get("/v1/nodes/<node_name>/desired")
    @require_node_auth
    def get_desired(node_name: str):
        with db_connect() as conn:
            row = conn.execute(
                """
                SELECT node_name, generation, profile, state_json, desired_hash, updated_at
                FROM desired_states
                WHERE node_name = ?
                """,
                (node_name,),
            ).fetchone()

        if row is None:
            return json_error("desired_state_not_found", 404)

        return jsonify(
            {
                "node_name": row["node_name"],
                "generation": row["generation"],
                "profile": row["profile"],
                "state": json_loads(row["state_json"]),
                "desired_hash": row["desired_hash"],
                "updated_at": row["updated_at"],
            }
        )

    @app.post("/v1/nodes/<node_name>/heartbeat")
    @require_node_auth
    def post_heartbeat(node_name: str):
        payload = request.get_json(silent=True)
        if not isinstance(payload, dict):
            return json_error("invalid_json", 400)

        required = (
            "agent_version",
            "runtime_hash",
            "persisted_hash",
            "runtime_rule_count",
            "persisted_rule_count",
            "runtime_jump",
            "persisted_jump",
            "health_state",
        )
        missing = [key for key in required if key not in payload]
        if missing:
            return jsonify({"error": "missing_fields", "fields": missing}), 400

        if payload["health_state"] not in HEALTH_STATES:
            return json_error("invalid_health_state", 400)

        numeric_fields = (
            "runtime_rule_count",
            "persisted_rule_count",
            "runtime_jump",
            "persisted_jump",
        )
        if any(
            not isinstance(payload[key], int) or isinstance(payload[key], bool)
            for key in numeric_fields
        ):
            return json_error("invalid_numeric_field", 400)

        now = utc_now()
        with db_connect() as conn:
            conn.execute(
                """
                INSERT INTO node_health (
                    node_name, last_seen_at, agent_version, desired_generation,
                    runtime_hash, persisted_hash, runtime_rule_count,
                    persisted_rule_count, runtime_jump, persisted_jump,
                    health_state, last_payload_json
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(node_name) DO UPDATE SET
                    last_seen_at=excluded.last_seen_at,
                    agent_version=excluded.agent_version,
                    desired_generation=excluded.desired_generation,
                    runtime_hash=excluded.runtime_hash,
                    persisted_hash=excluded.persisted_hash,
                    runtime_rule_count=excluded.runtime_rule_count,
                    persisted_rule_count=excluded.persisted_rule_count,
                    runtime_jump=excluded.runtime_jump,
                    persisted_jump=excluded.persisted_jump,
                    health_state=excluded.health_state,
                    last_payload_json=excluded.last_payload_json
                """,
                (
                    node_name,
                    now,
                    str(payload["agent_version"]),
                    payload.get("desired_generation"),
                    str(payload["runtime_hash"]),
                    str(payload["persisted_hash"]),
                    payload["runtime_rule_count"],
                    payload["persisted_rule_count"],
                    payload["runtime_jump"],
                    payload["persisted_jump"],
                    payload["health_state"],
                    json_dumps(payload),
                ),
            )
            conn.execute(
                """
                INSERT INTO audit_events(node_name, event_type, details_json, created_at)
                VALUES (?, 'HEARTBEAT', ?, ?)
                """,
                (node_name, json_dumps(payload), now),
            )
            conn.commit()

        return "", 204

    @app.post("/v1/nodes/<node_name>/actions/<action_id>/result")
    @require_node_auth
    def post_action_result(node_name: str, action_id: str):
        payload = request.get_json(silent=True)
        if not isinstance(payload, dict):
            return json_error("invalid_json", 400)

        if payload.get("status") not in ACTION_STATUSES:
            return json_error("invalid_action_status", 400)

        if not isinstance(payload.get("generation"), int):
            return json_error("invalid_generation", 400)

        with db_connect() as conn:
            action = conn.execute(
                """
                SELECT action_id, node_name, generation, status
                FROM actions
                WHERE action_id = ? AND node_name = ?
                """,
                (action_id, node_name),
            ).fetchone()

            if action is None:
                return json_error("action_not_found", 404)

            if (
                action["generation"] != payload["generation"]
                or action["status"] not in {"PENDING", "APPLYING"}
            ):
                return json_error("stale_action", 409)

            now = utc_now()
            conn.execute(
                """
                UPDATE actions
                SET status = ?, result_json = ?, updated_at = ?
                WHERE action_id = ?
                """,
                (
                    payload["status"],
                    json_dumps(payload),
                    now,
                    action_id,
                ),
            )
            conn.execute(
                """
                INSERT INTO audit_events(node_name, event_type, details_json, created_at)
                VALUES (?, 'ACTION_RESULT', ?, ?)
                """,
                (
                    node_name,
                    json_dumps({"action_id": action_id, **payload}),
                    now,
                ),
            )
            conn.commit()

        return "", 204


if __name__ == "__main__":
    create_app().run(
        host=os.environ.get("IP_ADMIN_BIND", "127.0.0.1"),
        port=int(os.environ.get("IP_ADMIN_PORT", "8080")),
        debug=False,
    )
