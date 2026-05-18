#!/usr/bin/env bash
set -euo pipefail

log_file="$(mktemp "${TMPDIR:-/tmp}/mbor-moon-check.XXXXXX.log")"
trap 'rm -f "$log_file"' EXIT

moon check 2>&1 | tee "$log_file"

warning_count="$(grep -c '^Warning:' "$log_file" || true)"
if [[ "$warning_count" != "0" ]]; then
  echo "::error::moon check emitted ${warning_count} warning(s)." >&2
  exit 1
fi
