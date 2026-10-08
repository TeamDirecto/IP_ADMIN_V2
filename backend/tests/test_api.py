from __future__ import annotations

import hashlib
import json
import tempfile
import unittest
from pathlib import Path

from backend.app import create_app, token_hash, utc_now
from backend.db import connect


class ApiTestCase(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.db_path = str(Path(self.tmp.name) / "test.sqlite3")
        self.app = create_app(self.db_path)
        self.client = self.app.test_client()
        self.node = "test-node"
        self.token = "test-secret-token"

        now = utc_now()
        with connect(self.db_path) as conn:
            conn.execute(
                """
                INSERT INTO nodes(node_name, token_sha256, enabled, created_at, updated_at)
                VALUES (?, ?, 1, ?, ?)
                """,
                (self.node, token_hash(self.token), now, now),
            )
            desired = {"ips": ["189.203.38.123"], "ports": {"tcp": [443]}}
            canonical = json.dumps(desired, separators=(",", ":"), sort_keys=True)
            conn.execute(
                """
                INSERT INTO desired_states(
                    node_name, generation, profile, state_json, desired_hash, updated_at
                )
                VALUES (?, ?, ?, ?, ?, ?)
                """,
                (
                    self.node,
                    1,
                    "legacy-compatible",
                    canonical,
                    hashlib.sha256(canonical.encode()).hexdigest(),
                    now,
                ),
            )
            conn.execute(
                """
                INSERT INTO actions(
                    action_id, node_name, generation, action_type, status,
                    payload_json, created_at, updated_at
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    "act-1",
                    self.node,
                    1,
                    "RECONCILE",
                    "PENDING",
                    "{}",
                    now,
                    now,
                ),
            )
            conn.commit()

    def tearDown(self):
        self.tmp.cleanup()

    def auth(self):
        return {"Authorization": f"Bearer {self.token}"}

    def test_healthz(self):
        response = self.client.get("/healthz")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json["status"], "ok")

    def test_desired_requires_auth(self):
        response = self.client.get(f"/v1/nodes/{self.node}/desired")
        self.assertEqual(response.status_code, 401)

    def test_desired_returns_generation_and_hash(self):
        response = self.client.get(
            f"/v1/nodes/{self.node}/desired",
            headers=self.auth(),
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json["generation"], 1)
        self.assertEqual(response.json["state"]["ips"], ["189.203.38.123"])

    def test_heartbeat_is_stored(self):
        payload = {
            "agent_version": "0.1.1",
            "runtime_hash": "a" * 64,
            "persisted_hash": "a" * 64,
            "runtime_rule_count": 2,
            "persisted_rule_count": 2,
            "runtime_jump": 1,
            "persisted_jump": 1,
            "health_state": "SYNCED",
            "desired_generation": 1,
        }
        response = self.client.post(
            f"/v1/nodes/{self.node}/heartbeat",
            headers=self.auth(),
            json=payload,
        )
        self.assertEqual(response.status_code, 204)

        with connect(self.db_path) as conn:
            row = conn.execute(
                "SELECT health_state, desired_generation FROM node_health WHERE node_name = ?",
                (self.node,),
            ).fetchone()

        self.assertEqual(row["health_state"], "SYNCED")
        self.assertEqual(row["desired_generation"], 1)

    def test_stale_action_is_rejected(self):
        response = self.client.post(
            f"/v1/nodes/{self.node}/actions/act-1/result",
            headers=self.auth(),
            json={"generation": 2, "status": "SUCCEEDED"},
        )
        self.assertEqual(response.status_code, 409)

    def test_action_result_is_accepted_for_current_generation(self):
        response = self.client.post(
            f"/v1/nodes/{self.node}/actions/act-1/result",
            headers=self.auth(),
            json={
                "generation": 1,
                "status": "SUCCEEDED",
                "observed": {"runtime_hash": "a" * 64},
            },
        )
        self.assertEqual(response.status_code, 204)

        with connect(self.db_path) as conn:
            row = conn.execute(
                "SELECT status FROM actions WHERE action_id = 'act-1'"
            ).fetchone()

        self.assertEqual(row["status"], "SUCCEEDED")


if __name__ == "__main__":
    unittest.main()
