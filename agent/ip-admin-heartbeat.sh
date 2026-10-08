#!/bin/bash
# IP_ADMIN_V2 heartbeat reporter 0.1.1
set -u

BACKEND_URL="${IP_ADMIN_BACKEND_URL:-}"
NODE_NAME="${IP_ADMIN_NODE_NAME:-}"
TOKEN_FILE="${IP_ADMIN_TOKEN_FILE:-/etc/ip-admin-v2/node.token}"
AGENT="${IP_ADMIN_AGENT:-/root/bin/ip-admin-agent.sh}"
AGENT_VERSION="${IP_ADMIN_AGENT_VERSION:-0.1.3}"
CURL="${IP_ADMIN_CURL:-/usr/bin/curl}"

if [ -z "$BACKEND_URL" ] || [ -z "$NODE_NAME" ]; then
  echo "SKIP: backend or node name not configured."
  exit 0
fi

if [ ! -x "$CURL" ] || [ ! -r "$TOKEN_FILE" ] || [ ! -r "$AGENT" ]; then
  echo "SKIP: heartbeat dependencies are not available."
  exit 0
fi

TOKEN="$(cat "$TOKEN_FILE")"
if [ -z "$TOKEN" ]; then
  echo "SKIP: empty node token."
  exit 0
fi

OBSERVED="$(bash "$AGENT" 2>/dev/null)"
OBSERVED_RC=$?

if [ -z "$OBSERVED" ]; then
  echo "SKIP: observer returned no payload."
  exit 0
fi

DESIRED="$("$CURL" -4fsS   --connect-timeout 3   --max-time 5   -H "Authorization: Bearer $TOKEN"   "$BACKEND_URL/v1/nodes/$NODE_NAME/desired" 2>/dev/null)" || {
  echo "SKIP: desired state unavailable."
  exit 0
}

PAYLOAD="$(
  python3 - "$OBSERVED" "$DESIRED" "$AGENT_VERSION" <<'PY'
import json
import sys

observed = json.loads(sys.argv[1])
desired = json.loads(sys.argv[2])
agent_version = sys.argv[3]

payload = {
    "agent_version": agent_version,
    "runtime_hash": observed.get("runtime_hash", ""),
    "persisted_hash": observed.get("persisted_hash", ""),
    "runtime_rule_count": observed.get("runtime_rule_count", 0),
    "persisted_rule_count": observed.get("persisted_rule_count", 0),
    "runtime_jump": observed.get("runtime_jump", 0),
    "persisted_jump": observed.get("persisted_jump", 0),
    "health_state": observed.get("state", "ERROR"),
    "desired_generation": desired.get("generation"),
}

print(json.dumps(payload, separators=(",", ":"), sort_keys=True))
PY
)" || {
  echo "SKIP: heartbeat payload could not be built."
  exit 0
}

if "$CURL"   -4   -fsS   --connect-timeout 3   --max-time 5   -H "Authorization: Bearer $TOKEN"   -H "Content-Type: application/json"   --data "$PAYLOAD"   "$BACKEND_URL/v1/nodes/$NODE_NAME/heartbeat"   >/dev/null 2>&1
then
  echo "OK: heartbeat sent node=$NODE_NAME observer_rc=$OBSERVED_RC state=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["health_state"])' <<<"$PAYLOAD")"
else
  echo "SKIP: heartbeat POST failed."
fi

exit 0
