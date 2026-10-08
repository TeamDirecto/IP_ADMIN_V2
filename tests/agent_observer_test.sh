#!/bin/bash
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
AGENT="$ROOT/agent/ip-admin-agent.sh"
TMP="$(mktemp -d /tmp/ip-admin-v2-test.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/save" <<'EOF_SAVE'
#!/bin/bash
cat <<'EOF_RULES'
*filter
:INPUT DROP [0:0]
:IPMANAGER-IN - [0:0]
-A INPUT -j IPMANAGER-IN
-A IPMANAGER-IN -s 189.203.38.123/32 -p tcp -j ACCEPT
-A IPMANAGER-IN -s 189.203.38.123/32 -p udp -j ACCEPT
COMMIT
EOF_RULES
EOF_SAVE
chmod +x "$TMP/save"

cat > "$TMP/restore" <<'EOF_RESTORE'
#!/bin/bash
exit 0
EOF_RESTORE
chmod +x "$TMP/restore"

cat > "$TMP/rules.v4" <<'EOF_RULES'
*filter
:INPUT DROP [0:0]
:IPMANAGER-IN - [0:0]
-A INPUT -j IPMANAGER-IN
-A IPMANAGER-IN -s 189.203.38.123/32 -p tcp -j ACCEPT
-A IPMANAGER-IN -s 189.203.38.123/32 -p udp -j ACCEPT
COMMIT
EOF_RULES

bash -n "$AGENT"

out="$(IP_ADMIN_RULES_FILE="$TMP/rules.v4" IP_ADMIN_IPTABLES_SAVE="$TMP/save" IP_ADMIN_IPTABLES_RESTORE="$TMP/restore" "$AGENT")"
printf '%s\n' "$out" | grep -q '"state":"SYNCED"'

echo "agent observer tests: OK"
