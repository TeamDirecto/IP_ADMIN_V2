#!/bin/bash
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
REPORTER="$ROOT/agent/ip-admin-heartbeat.sh"
TMP="$(mktemp -d /tmp/ip-admin-v2-heartbeat.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/agent" <<'EOF_AGENT'
#!/bin/bash
echo '{"state":"DRIFT","runtime_hash":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","persisted_hash":"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb","runtime_rule_count":10,"persisted_rule_count":9,"runtime_jump":1,"persisted_jump":1}'
exit 1
EOF_AGENT
chmod +x "$TMP/agent"

cat > "$TMP/curl" <<'EOF_CURL'
#!/bin/bash
set -eu

printf '%s\n' "$*" >> "$TMP/calls"
count="$(wc -l < "$TMP/calls")"

if [ "$count" -eq 1 ]; then
  printf '%s\n' '{"node_name":"test-node","generation":7,"profile":"test","state":{},"desired_hash":"cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc","updated_at":"2026-10-08T00:00:00+00:00"}'
fi

exit 0
EOF_CURL
chmod +x "$TMP/curl"

printf '%s\n' 'test-secret' > "$TMP/token"
chmod 600 "$TMP/token"

bash -n "$REPORTER"

output="$(
  IP_ADMIN_BACKEND_URL="https://example.invalid"   IP_ADMIN_NODE_NAME="test-node"   IP_ADMIN_TOKEN_FILE="$TMP/token"   IP_ADMIN_AGENT="$TMP/agent"   IP_ADMIN_CURL="$TMP/curl"   bash "$REPORTER"
)"

printf '%s\n' "$output" | grep -q 'OK: heartbeat sent'
[ "$(wc -l < "$TMP/calls")" -eq 2 ]
grep -q -- '--data' "$TMP/calls"
grep -q 'DRIFT' "$TMP/calls"

echo "heartbeat reporter tests: OK"
