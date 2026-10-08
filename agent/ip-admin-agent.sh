#!/bin/bash
# IP_ADMIN_V2 observer 0.1.0
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

runtime_ips="$(printf '%s\n' "$runtime" | awk -v c="$CHAIN" '$1=="-A" && $2==c {for(i=1;i<=NF;i++) if($i=="-s"){x=$(i+1); sub(/\/32$/,"",x); print x}}' | sort -u)"
persisted_ips="$(awk -v c="$CHAIN" '$1=="-A" && $2==c {for(i=1;i<=NF;i++) if($i=="-s"){x=$(i+1); sub(/\/32$/,"",x); print x}}' "$RULES_FILE" | sort -u)"

runtime_hash="$(printf '%s' "$runtime_ips" | sha256sum | awk '{print $1}')"
persisted_hash="$(printf '%s' "$persisted_ips" | sha256sum | awk '{print $1}')"

if [ "$runtime_hash" = "$persisted_hash" ]; then state=SYNCED; else state=DRIFT; fi

printf '{"state":"%s","runtime_hash":"%s","persisted_hash":"%s"}\n' "$state" "$runtime_hash" "$persisted_hash"
[ "$state" = SYNCED ]
