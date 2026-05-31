#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/lib.sh"

HONGGFUZZ_VERSION="${HONGGFUZZ_VERSION:-2.6}"
PREFIX="${HONGGFUZZ_PREFIX:-/opt/honggfuzz}"
SRC=/tmp/honggfuzz

retry git clone --depth 1 --branch "${HONGGFUZZ_VERSION}" \
      https://github.com/google/honggfuzz.git "${SRC}" \
  || retry git clone --depth 1 https://github.com/google/honggfuzz.git "${SRC}"

make -C "${SRC}" -j"$(nproc)"
make -C "${SRC}" install PREFIX="${PREFIX}"

strip_dir "${PREFIX}"
rm -rf "${SRC}"
echo "[ok] honggfuzz ${HONGGFUZZ_VERSION} -> ${PREFIX}"
