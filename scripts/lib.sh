#!/usr/bin/env bash
set -euo pipefail

strip_dir() {
  find "$1" -type f \( -name '*.so*' -o -perm -u+x \) \
    -exec strip --strip-unneeded {} + 2>/dev/null || true
}

retry() {
  local n=0 max="${RETRY_MAX:-3}"
  until "$@"; do
    n=$((n + 1))
    [ "$n" -ge "$max" ] && return 1
    sleep "$((n * 3))"
  done
}
