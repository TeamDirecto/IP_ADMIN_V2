# Backend

Minimal central API for IP_ADMIN_V2.

## Safety boundary

This backend currently **does not write iptables** and does not modify any production node.

The current responsibilities are:

- authenticate a node;
- return its desired state;
- receive heartbeats;
- persist node health;
- receive action results;
- reject stale action results;
- write an audit trail.

The agent remains read-only in this phase.

## Runtime

The backend uses Flask with SQLite. SQLite is configured for WAL mode and a busy timeout because heartbeats are writes while desired-state reads may occur concurrently.

Install:

```bash
python3 -m venv .venv
. .venv/bin/activate
pip install -r backend/requirements.txt
```

Initialize:

```bash
python3 -m backend.manage init-db
```

Provision a node token. The plaintext token is printed once and must not be committed:

```bash
python3 -m backend.manage add-node AliadosD3
```

Set desired state from a JSON file:

```bash
python3 -m backend.manage set-desired \
  AliadosD3 \
  --generation 1 \
  --profile legacy-compatible \
  --state-file desired/AliadosD3.json
```

Run locally only:

```bash
FLASK_APP=backend.wsgi flask run --host 127.0.0.1 --port 8080
```

For production, use a WSGI server and place TLS/authentication controls in front of the service. Do not use Flask's development server as the production service.

## Database

Default:

```
backend/instance/ip_admin_v2.sqlite3
```

Override with:

```bash
export IP_ADMIN_DB_PATH=/var/lib/ip-admin-v2/ip_admin_v2.sqlite3
```

The database path is runtime state and must never be committed.

## Authentication

Each node has a SHA-256 hash of its bearer token. Tokens are never returned by the API.

Requests use:

```
Authorization: Bearer <node-token>
```

A node can only access its own desired state, heartbeat endpoint, and action-result endpoint.

## Next safety boundary

Before enabling writes on any node we will add:

1. explicit DRY_RUN;
2. action generation and expiry;
3. pre-change snapshot;
4. iptables-restore --test;
5. atomic apply;
6. post-change validation;
7. automatic rollback;
8. persistent evidence of the result.
