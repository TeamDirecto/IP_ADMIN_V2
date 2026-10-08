PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS nodes (
    node_name TEXT PRIMARY KEY,
    token_sha256 TEXT NOT NULL,
    enabled INTEGER NOT NULL DEFAULT 1 CHECK (enabled IN (0,1)),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS desired_states (
    node_name TEXT PRIMARY KEY REFERENCES nodes(node_name) ON DELETE CASCADE,
    generation INTEGER NOT NULL CHECK (generation >= 1),
    profile TEXT NOT NULL,
    state_json TEXT NOT NULL,
    desired_hash TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS node_health (
    node_name TEXT PRIMARY KEY REFERENCES nodes(node_name) ON DELETE CASCADE,
    last_seen_at TEXT NOT NULL,
    agent_version TEXT NOT NULL,
    desired_generation INTEGER,
    runtime_hash TEXT NOT NULL,
    persisted_hash TEXT NOT NULL,
    runtime_rule_count INTEGER NOT NULL DEFAULT 0,
    persisted_rule_count INTEGER NOT NULL DEFAULT 0,
    runtime_jump INTEGER NOT NULL DEFAULT 0,
    persisted_jump INTEGER NOT NULL DEFAULT 0,
    health_state TEXT NOT NULL CHECK (health_state IN ('SYNCED','DRIFT','STALE','ERROR')),
    last_payload_json TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS actions (
    action_id TEXT PRIMARY KEY,
    node_name TEXT NOT NULL REFERENCES nodes(node_name) ON DELETE CASCADE,
    generation INTEGER NOT NULL CHECK (generation >= 1),
    action_type TEXT NOT NULL CHECK (action_type IN ('ADD','REMOVE','RECONCILE')),
    status TEXT NOT NULL CHECK (status IN ('PENDING','APPLYING','SUCCEEDED','FAILED','CANCELLED')),
    payload_json TEXT NOT NULL,
    result_json TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS audit_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    node_name TEXT,
    event_type TEXT NOT NULL,
    details_json TEXT NOT NULL,
    created_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_audit_events_node_time
    ON audit_events(node_name, created_at);

CREATE INDEX IF NOT EXISTS idx_actions_node_status
    ON actions(node_name, status);
