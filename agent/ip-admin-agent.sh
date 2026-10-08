#!/bin/bash
# IP_ADMIN_V2 observer 0.1.3
set -u

RULES_FILE="${IP_ADMIN_RULES_FILE:-/etc/iptables/rules.v4}"
SAVE="${IP_ADMIN_IPTABLES_SAVE:-/usr/sbin/iptables-save}"
RESTORE="${IP_ADMIN_IPTABLES_RESTORE:-/usr/sbin/iptables-restore}"
CHAIN="${IP_ADMIN_CHAIN:-IPMANAGER-IN}"

if [ ! -x "$SAVE" ] || [ ! -r "$RULES_FILE" ]; then
  echo '{"state":"ERROR","reason":"missing_runtime_or_rules_file"}'
  exit 1
fi

runtime="$("$SAVE" -t filter 2>/dev/null)" || {
  echo '{"state":"ERROR","reason":"runtime_read_failed"}'
  exit 1
}

if ! "$RESTORE" --test < "$RULES_FILE" >/dev/null 2>&1; then
  echo '{"state":"ERROR","reason":"persisted_rules_invalid"}'
  exit 1
fi

runtime_rules="$(printf '%s\n' "$runtime" | awk -v c="$CHAIN" '$1=="-A" && $2==c' | sort)"
persisted_rules="$(awk -v c="$CHAIN" '$1=="-A" && $2==c' "$RULES_FILE" | sort)"

runtime_rule_count="$(printf '%s\n' "$runtime_rules" | awk 'NF{c++} END{print c+0}')"
persisted_rule_count="$(printf '%s\n' "$persisted_rules" | awk 'NF{c++} END{print c+0}')"

runtime_chain="$(printf '%s\n' "$runtime" | grep -c "^:$CHAIN " 2>/dev/null || true)"
persisted_chain="$(grep -c "^:$CHAIN " "$RULES_FILE" 2>/dev/null || true)"
runtime_jump="$(printf '%s\n' "$runtime" | awk -v c="$CHAIN" '$1=="-A" && $2=="INPUT" {for(i=1;i<=NF;i++) if($i=="-j" && $(i+1)==c) n++} END{print n+0}')"
persisted_jump="$(awk -v c="$CHAIN" '$1=="-A" && $2=="INPUT" {for(i=1;i<=NF;i++) if($i=="-j" && $(i+1)==c) n++} END{print n+0}' "$RULES_FILE")"

runtime_hash="$(printf '%s' "$runtime_rules" | sha256sum | awk '{print $1}')"
persisted_hash="$(printf '%s' "$persisted_rules" | sha256sum | awk '{print $1}')"

if [ "$runtime_chain" -ge 1 ] &&
   [ "$persisted_chain" -ge 1 ] &&
   [ "$runtime_jump" -ge 1 ] &&
   [ "$persisted_jump" -ge 1 ] &&
   [ "$runtime_rule_count" -eq "$persisted_rule_count" ] &&
   [ "$runtime_hash" = "$persisted_hash" ]; then
  state=SYNCED
else
  state=DRIFT
fi

printf '{"state":"%s","runtime_hash":"%s","persisted_hash":"%s","runtime_rule_count":%s,"persisted_rule_count":%s,"runtime_jump":%s,"persisted_jump":%s}\n'   "$state" "$runtime_hash" "$persisted_hash" "$runtime_rule_count" "$persisted_rule_count" "$runtime_jump" "$persisted_jump"

[ "$state" = SYNCED ]
