# API Contract V2

This document defines the initial pull-based contract between the central service and node agents.

## Authentication

Node endpoints require:

```
Authorization: Bearer <node-token>
```

The backend stores only a SHA-256 hash of the token.

A node token is scoped to one `node_name`. A node cannot read or write another node's state.

## Node desired state

```
GET /v1/nodes/{node_name}/desired
```

Returns:

- `node_name`
- `generation`
- `profile`
- `state`
- `desired_hash`
- `updated_at`

A missing desired state returns `404`.

The generation is monotonic. A node must never silently apply an older generation.

## Heartbeat

```
POST /v1/nodes/{node_name}/heartbeat
```

Reports:

- agent version;
- desired generation observed by the agent;
- runtime hash;
- persisted hash;
- runtime/persisted rule counts;
- runtime/persisted INPUT jump counts;
- health state.

The backend stores the latest health snapshot and an immutable audit event.

## Action result

```
POST /v1/nodes/{node_name}/actions/{action_id}/result
```

Reports completion or failure plus observed state.

The backend accepts a result only when:

1. the action belongs to the authenticated node;
2. the action exists;
3. the generation matches;
4. the action is still `PENDING` or `APPLYING`.

Otherwise the result is rejected as stale with `409`.

## State ownership

The central backend owns DESIRED state.

The node owns APPLIED/PERSISTED observation.

During the current phase, the agent has no write permission.

## Legacy compatibility

Legacy remains available for nodes that have not migrated. V2 must not silently write to legacy-owned resources.

The IVR/legacy path remains independent until a node is explicitly migrated.

## Versioning

Breaking changes require a new API version.

The current API is `v1` and is intentionally small. New write operations will be introduced only after DRY_RUN, pre-change validation, rollback, and post-change evidence are implemented.
