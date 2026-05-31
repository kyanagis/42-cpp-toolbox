#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/lib.sh"

# IKOS official: https://github.com/NASA-SW-VnV/ikos
# IKOS install guide (Ubuntu): https://github.com/NASA-SW-VnV/ikos/blob/master/doc/install/UBUNTU.md
# IKOS dependencies: https://github.com/NASA-SW-VnV/ikos#dependencies
# IKOS analyzer docs: https://github.com/NASA-SW-VnV/ikos/blob/master/analyzer/README.md
# NASA Software V&V: https://github.com/NASA-SW-VnV

IKOS_VERSION="${IKOS_VERSION:-v3.5}"
PREFIX="${IKOS_PREFIX:-/opt/ikos}"
SRC=/tmp/ikos

retry git clone --depth 1 --branch "${IKOS_VERSION}" \
      https://github.com/NASA-SW-VnV/ikos.git "${SRC}" \
  || retry git clone --depth 1 https://github.com/NASA-SW-VnV/ikos.git "${SRC}"

# IKOSはLLVM14前提。https://github.com/NASA-SW-VnV/ikos#dependencies
cmake -G Ninja -S "${SRC}" -B "${SRC}/build" \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
      -DLLVM_CONFIG_EXECUTABLE=/usr/bin/llvm-config-14
cmake --build "${SRC}/build" -j"$(nproc)"
cmake --install "${SRC}/build"

strip_dir "${PREFIX}"
rm -rf "${SRC}"
echo "[ok] ikos ${IKOS_VERSION} -> ${PREFIX}"
