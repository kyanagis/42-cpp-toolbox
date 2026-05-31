#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/lib.sh"

# honggfuzz official: https://honggfuzz.dev/
# honggfuzz repo: https://github.com/google/honggfuzz
# honggfuzz usage: https://github.com/google/honggfuzz/blob/master/docs/USAGE.md
# honggfuzz build deps: https://github.com/google/honggfuzz#requirements

# 2.6タグはbinutils2.39のstyled disassembler APIに未対応でビルド不可のためmaster commitに固定。https://github.com/google/honggfuzz/blob/master/linux/bfd.c
HONGGFUZZ_VERSION="${HONGGFUZZ_VERSION:-48790f7b18f30ba4a95272ea290b720662ed56c9}"
PREFIX="${HONGGFUZZ_PREFIX:-/opt/honggfuzz}"
SRC=/tmp/honggfuzz

rm -rf "${SRC}"
git init -q "${SRC}"
git -C "${SRC}" remote add origin https://github.com/google/honggfuzz.git
retry git -C "${SRC}" fetch --depth 1 origin "${HONGGFUZZ_VERSION}"
git -C "${SRC}" checkout -q FETCH_HEAD

make -C "${SRC}" -j"$(nproc)"
make -C "${SRC}" install PREFIX="${PREFIX}"

strip_dir "${PREFIX}"
rm -rf "${SRC}"
echo "[ok] honggfuzz ${HONGGFUZZ_VERSION} -> ${PREFIX}"
