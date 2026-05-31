#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/lib.sh"

RADAMSA_VERSION="${RADAMSA_VERSION:-v0.7}"
PREFIX="${RADAMSA_PREFIX:-/opt/radamsa}"
SRC=/tmp/radamsa

retry git clone --depth 1 --branch "${RADAMSA_VERSION}" \
      https://gitlab.com/akihe/radamsa.git "${SRC}" \
  || retry git clone --depth 1 https://github.com/aoh/radamsa.git "${SRC}"

make -C "${SRC}" -j"$(nproc)"
make -C "${SRC}" PREFIX="${PREFIX}" install

strip_dir "${PREFIX}"
rm -rf "${SRC}"
echo "[ok] radamsa ${RADAMSA_VERSION} -> ${PREFIX}"
