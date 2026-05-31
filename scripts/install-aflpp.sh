#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/lib.sh"

AFLPP_VERSION="${AFLPP_VERSION:-v4.40c}"
PREFIX="${AFLPP_PREFIX:-/opt/aflplusplus}"
SRC=/tmp/aflpp

retry git clone --depth 1 --branch "${AFLPP_VERSION}" \
      https://github.com/AFLplusplus/AFLplusplus.git "${SRC}" \
  || retry git clone --depth 1 https://github.com/AFLplusplus/AFLplusplus.git "${SRC}"

export LLVM_CONFIG=llvm-config-14 CC=gcc-12 CXX=g++-12
make -C "${SRC}" -j"$(nproc)" PREFIX="${PREFIX}" all
make -C "${SRC}" PREFIX="${PREFIX}" install

strip_dir "${PREFIX}"
rm -rf "${SRC}"
echo "[ok] aflplusplus ${AFLPP_VERSION} -> ${PREFIX}"
