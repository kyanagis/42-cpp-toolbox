#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/lib.sh"

RADARE2_VERSION="${RADARE2_VERSION:-6.1.4}"
SRC=/tmp/radare2

retry git clone --depth 1 --branch "${RADARE2_VERSION}" \
      https://github.com/radareorg/radare2.git "${SRC}" \
  || retry git clone --depth 1 https://github.com/radareorg/radare2.git "${SRC}"

# sys/install.shはsymstall（ソースへのsymlink）でソース削除後に壊れるため使わない。https://github.com/radareorg/radare2/blob/master/sys/install.sh
if [ -x "${SRC}/configure" ]; then
  ( cd "${SRC}" && ./configure --prefix=/usr/local && make -j"$(nproc)" && make install )
else
  meson setup --prefix=/usr/local "${SRC}/build" "${SRC}"
  ninja -C "${SRC}/build"
  ninja -C "${SRC}/build" install
fi

ldconfig
strip_dir /usr/local/lib
rm -rf "${SRC}"
r2 -version | head -1
echo "[ok] radare2 ${RADARE2_VERSION}"
