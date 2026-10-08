from __future__ import annotations

import json
import os
import sqlite3
from pathlib import Path
from typing import Any

DEFAULT_DB = os.environ.get(
    "IP_ADMIN_DB_PATH",
    str(Path(__file__).resolve().parent / "instance" / "ip_admin_v2.sqlite3"),
)

SCHEMA = Path(__file__).resolve().parent / "schema.sql"


def connect(db_path: str | None = None) -> sqlite3.Connection:
    path = db_path or DEFAULT_DB
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(path, timeout=10)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    conn.execute("PRAGMA busy_timeout = 10000")
    conn.execute("PRAGMA journal_mode = WAL")
    return conn


def init_db(db_path: str | None = None) -> None:
    with connect(db_path) as conn:
        conn.executescript(SCHEMA.read_text(encoding="utf-8"))
        conn.commit()


def row_dict(row: sqlite3.Row | None) -> dict[str, Any] | None:
    return dict(row) if row is not None else None


def json_loads(value: str | None) -> Any:
    return json.loads(value) if value else None


def json_dumps(value: Any) -> str:
    return json.dumps(value, separators=(",", ":"), sort_keys=True)
