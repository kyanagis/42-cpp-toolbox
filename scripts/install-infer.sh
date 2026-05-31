#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/lib.sh"

# Infer1.3.0はglibc>=2.38要求でjammy（2.35）非対応。新しい順に動く版を採る。https://github.com/facebook/infer/releases
try_install() {
  local ver="$1" asset="$2" dir="$3"
  retry curl -fSL "https://github.com/facebook/infer/releases/download/v${ver}/${asset}" -o /tmp/infer.tar.xz || return 1
  rm -rf /opt/infer-* /opt/infer
  tar -C /opt -xJf /tmp/infer.tar.xz
  rm -f /tmp/infer.tar.xz
  ln -sfn "/opt/${dir}" /opt/infer
  /opt/infer/bin/infer --version >/dev/null 2>&1 || return 1
  /opt/infer/bin/infer --version | head -1
}

try_install 1.2.0 infer-linux-x86_64-v1.2.0.tar.xz infer-linux-x86_64-v1.2.0 \
  || try_install 1.1.0 infer-linux64-v1.1.0.tar.xz infer-linux64-v1.1.0 \
  || { echo "ERROR: no glibc-compatible Infer release found" >&2; exit 1; }

echo "[ok] infer -> /opt/infer"
