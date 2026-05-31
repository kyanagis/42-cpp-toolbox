#!/usr/bin/env bash
set -euo pipefail

if [ -n "${HOST_UID:-}" ] && [ -n "${HOST_GID:-}" ] && [ "$(id -u)" = "0" ]; then
  export HOME=/work
  exec setpriv --reuid "${HOST_UID}" --regid "${HOST_GID}" --init-groups -- "$@"
fi

exec "$@"
