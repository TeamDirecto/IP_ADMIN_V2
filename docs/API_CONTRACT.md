# API Contract V2

This document defines the initial pull-based contract between the central service and node agents.

## Node desired state

GET /v1/nodes/{node_name}/desired

Returns the desired generation, profile, address list, and desired hash.

## Heartbeat

POST /v1/nodes/{node_name}/heartbeat

Reports agent version, desired generation, observed hashes, counts, and health state.

## Action result

POST /v1/nodes/{node_name}/actions/{action_id}/result

Reports completion or error with the observed state after validation.

## Legacy compatibility

Legacy remains available for nodes that have not migrated. V2 must not silently write to legacy-owned resources.

## Versioning

Breaking changes require a new API version.
