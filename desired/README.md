# Desired state

Desired state files are the Git-managed declaration of what a node should have.

Rules:

- one file per node;
- no credentials;
- no runtime counters;
- changes must be reviewed before promotion;
- generation must increase monotonically when the state changes;
- legacy-owned nodes remain excluded until explicitly migrated.

The backend management CLI can load a desired JSON document into the central database.

Example:

```
desired/example.json
```
