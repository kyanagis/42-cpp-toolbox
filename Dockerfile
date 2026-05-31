# syntax=docker/dockerfile:1

ARG IKOS_VERSION=v3.5
ARG AFLPP_VERSION=v4.40c
ARG HONGGFUZZ_VERSION=48790f7b18f30ba4a95272ea290b720662ed56c9
ARG RADAMSA_VERSION=v0.7
ARG RADARE2_VERSION=6.1.4
ARG PWNDBG_VERSION=2026.02.18
ARG LLVM_MODERN=19

FROM ubuntu:22.04 AS builder
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive
ARG IKOS_VERSION
ARG AFLPP_VERSION
ARG HONGGFUZZ_VERSION
ARG RADAMSA_VERSION

# キャッシュマウントでapt再取得を高速化しlists/archivesを層に残さない。https://docs.docker.com/build/cache/optimize/
# Ubuntu 22.04 (jammy): https://releases.ubuntu.com/22.04/
# LLVM: https://llvm.org/   Clang: https://clang.llvm.org/
# GCC: https://gcc.gnu.org/   CMake: https://cmake.org/   Ninja: https://ninja-build.org/
# Boost: https://www.boost.org/   GMP: https://gmplib.org/   libunwind: https://www.nongnu.org/libunwind/
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    rm -f /etc/apt/apt.conf.d/docker-clean \
 && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl wget git xz-utils \
      build-essential gcc-12 g++-12 gcc-12-plugin-dev \
      cmake ninja-build make pkg-config \
      python3 python3-dev python3-pip python3-setuptools \
      automake autoconf libtool bison flex \
      llvm-14 llvm-14-dev llvm-14-tools clang-14 libclang-14-dev lld-14 \
      libgmp-dev libboost-dev libboost-filesystem-dev libboost-thread-dev \
      libboost-test-dev python3-pygments libsqlite3-dev libtbb-dev libz-dev \
      libedit-dev libunwind-dev binutils-dev

COPY scripts/ /tmp/scripts/
RUN chmod +x /tmp/scripts/*.sh

RUN IKOS_VERSION="${IKOS_VERSION}" /tmp/scripts/install-ikos.sh
RUN AFLPP_VERSION="${AFLPP_VERSION}" /tmp/scripts/install-aflpp.sh
RUN RADAMSA_VERSION="${RADAMSA_VERSION}" /tmp/scripts/install-radamsa.sh
RUN HONGGFUZZ_VERSION="${HONGGFUZZ_VERSION}" /tmp/scripts/install-honggfuzz.sh


FROM ubuntu:22.04
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

LABEL org.opencontainers.image.title="42 Tokyo C++ Analysis Toolbox" \
      org.opencontainers.image.description="C/C++ dynamic + static analysis, fuzzing and interactive debugging toolbox (ASan/UBSan/TSan/MSan, valgrind, GEF/pwndbg/PEDA, AFL++, libFuzzer, honggfuzz, radamsa, IKOS, Infer, clang-tidy 14/19, cppcheck, Frama-C, IWYU, CodeChecker, pahole, lizard, and more)." \
      org.opencontainers.image.source="https://github.com/kyanagis/42-cpp-toolbox" \
      org.opencontainers.image.base.name="ubuntu:22.04"

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# --- official sites / install guides for the bundled apt tools ---
# Compilers/build: GCC https://gcc.gnu.org/  Clang/LLVM https://clang.llvm.org/  CMake https://cmake.org/
# Ninja https://ninja-build.org/  Meson https://mesonbuild.com/  Bear https://github.com/rizsotto/Bear
# ccache https://ccache.dev/  mold https://github.com/rui314/mold  hyperfine https://github.com/sharkdp/hyperfine
# Debug/dynamic: GDB https://www.sourceware.org/gdb/  rr https://rr-project.org/  strace https://strace.io/
# ltrace https://www.ltrace.org/  valgrind https://valgrind.org/  heaptrack https://github.com/KDE/heaptrack
# gperftools https://github.com/gperftools/gperftools  ElectricFence https://packages.ubuntu.com/jammy/electric-fence
# DUMA https://duma.sourceforge.net/
# Static analysis: cppcheck https://cppcheck.sourceforge.io/  IWYU https://include-what-you-use.org/
# flawfinder https://dwheeler.com/flawfinder/
# Coverage: lcov https://github.com/linux-test-project/lcov  gcovr https://gcovr.com/  kcov https://github.com/SimonKagstrom/kcov
# Binary/reverse: patchelf https://github.com/NixOS/patchelf  elfutils https://sourceware.org/elfutils/
# capstone https://www.capstone-engine.org/  checksec https://github.com/slimm609/checksec.sh
# Test frameworks: GoogleTest https://google.github.io/googletest/  Catch2 https://github.com/catchorg/Catch2
# doctest https://github.com/doctest/doctest  Criterion https://github.com/Snaipe/Criterion
# Extras: pahole/dwarves https://github.com/acmel/dwarves  universal-ctags https://ctags.io/
# CLI: ripgrep https://github.com/BurntSushi/ripgrep  fd https://github.com/sharkdp/fd  bat https://github.com/sharkdp/bat
# fzf https://github.com/junegunn/fzf  jq https://jqlang.github.io/jq/  neovim https://neovim.io/  tmux https://github.com/tmux/tmux
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    rm -f /etc/apt/apt.conf.d/docker-clean \
 && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl wget git gnupg lsb-release sudo locales \
      software-properties-common \
      vim neovim nano tmux less tree ripgrep fd-find fzf jq bat htop file \
      bsdmainutils xxd universal-ctags dwarves \
      python3 python3-pip python3-dev python3-venv ipython3 \
      build-essential gcc-11 g++-11 gcc-12 g++-12 gcc-12-plugin-dev \
      gcc-multilib make cmake ninja-build meson \
      autoconf automake libtool pkg-config bear ccache mold hyperfine \
      clang-14 clang-tidy-14 clang-tools-14 clang-format-14 \
      llvm-14 llvm-14-dev llvm-14-tools lld-14 lldb-14 \
      libclang-14-dev libc++-14-dev libc++abi-14-dev \
      libgmp-dev libboost-all-dev libsqlite3-dev libtbb-dev libz-dev libedit-dev \
      python3-pygments \
      gdb gdb-multiarch strace ltrace rr \
      valgrind heaptrack google-perftools libunwind8 \
      electric-fence duma \
      cppcheck iwyu flawfinder checksec \
      lcov gcovr kcov \
      binutils binutils-dev elfutils patchelf libcapstone-dev \
      libgtest-dev libgmock-dev catch2 doctest-dev libcriterion-dev

ARG LLVM_MODERN
# 既定clangは14のまま（ikosが読むLLVM14ビットコード生成のため）。最新側は併存。https://apt.llvm.org/
# LLVM apt repo: https://apt.llvm.org/
# clang-tidy: https://clang.llvm.org/extra/clang-tidy/
# clang-format: https://clang.llvm.org/docs/ClangFormat.html
# libc++: https://libcxx.llvm.org/
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    wget -qO /tmp/llvm.sh https://apt.llvm.org/llvm.sh \
 && chmod +x /tmp/llvm.sh \
 && /tmp/llvm.sh "${LLVM_MODERN}" \
 && apt-get install -y --no-install-recommends \
      "clang-tidy-${LLVM_MODERN}" "clang-format-${LLVM_MODERN}" "clang-tools-${LLVM_MODERN}" \
      "libc++-${LLVM_MODERN}-dev" "libc++abi-${LLVM_MODERN}-dev" \
 && rm -f /tmp/llvm.sh

RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 100 \
      --slave /usr/bin/g++ g++ /usr/bin/g++-12 \
 && update-alternatives --install /usr/bin/clang clang /usr/bin/clang-14 100 \
      --slave /usr/bin/clang++ clang++ /usr/bin/clang++-14 \
      --slave /usr/bin/clang-tidy clang-tidy /usr/bin/clang-tidy-14 \
      --slave /usr/bin/clang-format clang-format /usr/bin/clang-format-14 \
 && update-alternatives --install /usr/bin/cc cc /usr/bin/gcc 100 \
 && update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++ 100 \
 && ln -sf /usr/bin/scan-build-14    /usr/local/bin/scan-build \
 && ln -sf /usr/bin/scan-view-14     /usr/local/bin/scan-view \
 && ln -sf /usr/bin/analyze-build-14 /usr/local/bin/analyze-build \
 && ln -sf /usr/bin/llvm-symbolizer-14 /usr/local/bin/llvm-symbolizer \
 && ln -sf "$(command -v batcat)" /usr/local/bin/bat \
 && ln -sf "$(command -v fdfind)" /usr/local/bin/fd

# GoogleTest: https://google.github.io/googletest/
# GoogleTest CMake quickstart: https://google.github.io/googletest/quickstart-cmake.html
RUN cmake -S /usr/src/googletest -B /tmp/gtest -DCMAKE_BUILD_TYPE=Release \
 && cmake --build /tmp/gtest -j"$(nproc)" \
 && cmake --install /tmp/gtest \
 && rm -rf /tmp/gtest

ARG RADARE2_VERSION
COPY scripts/lib.sh scripts/install-radare2.sh /tmp/scripts/
RUN chmod +x /tmp/scripts/install-radare2.sh \
 && RADARE2_VERSION="${RADARE2_VERSION}" /tmp/scripts/install-radare2.sh

COPY --from=builder /opt/ikos        /opt/ikos
COPY --from=builder /opt/aflplusplus /opt/aflplusplus
COPY --from=builder /opt/radamsa     /opt/radamsa
COPY --from=builder /opt/honggfuzz   /opt/honggfuzz

COPY scripts/lib.sh scripts/install-infer.sh /tmp/scripts/
RUN chmod +x /tmp/scripts/install-infer.sh && /tmp/scripts/install-infer.sh

# pip-installed tools:
# CodeChecker https://github.com/Ericsson/codechecker  semgrep https://semgrep.dev/
# cpplint https://github.com/cpplint/cpplint  compiledb https://github.com/nickdiego/compiledb
# lizard https://github.com/terryyin/lizard  pwntools https://docs.pwntools.com/
# ROPgadget https://github.com/JonathanSalwan/ROPgadget  capstone https://www.capstone-engine.org/
RUN --mount=type=cache,target=/root/.cache/pip \
    pip3 install --upgrade pip wheel \
 && pip3 install \
      uv \
      codechecker semgrep cpplint compiledb lizard \
      pwntools ROPgadget capstone

# gdb front-ends:
# GEF https://hugsy.github.io/gef/  (repo https://github.com/hugsy/gef)
# pwndbg https://github.com/pwndbg/pwndbg
# PEDA https://github.com/longld/peda
ARG PWNDBG_VERSION
RUN mkdir -p /opt/gef \
 && wget -qO /opt/gef/gef.py https://raw.githubusercontent.com/hugsy/gef/main/gef.py \
 && git clone --depth 1 https://github.com/longld/peda.git /opt/peda \
 && git clone --depth 1 --branch "${PWNDBG_VERSION}" https://github.com/pwndbg/pwndbg /opt/pwndbg \
 && { cd /opt/pwndbg && ./setup.sh; } || echo "[warn] pwndbg setup best-effort; GEF/PEDA remain"

COPY config/gdbinit-gef /etc/gdb/gdbinit
COPY config/gdb-gef config/gdb-pwndbg config/gdb-peda /usr/local/bin/
RUN chmod +x /usr/local/bin/gdb-gef /usr/local/bin/gdb-pwndbg /usr/local/bin/gdb-peda

# Frama-Cはuniverse由来でビルド環境差を吸収するためベストエフォート。https://frama-c.com/
# Frama-C official: https://frama-c.com/
# Frama-C install: https://git.frama-c.com/pub/frama-c/-/blob/master/INSTALL.md
# Frama-C EVA plugin: https://frama-c.com/fc-plugins/eva.html
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    rm -f /etc/apt/apt.conf.d/docker-clean \
 && apt-get update \
 && apt-get install -y --no-install-recommends frama-c \
 || echo "[warn] frama-c best-effort install skipped"

ENV PATH="/opt/ikos/bin:/opt/infer/bin:/opt/aflplusplus/bin:/opt/radamsa/bin:/opt/honggfuzz/bin:${PATH}" \
    AFL_PATH="/opt/aflplusplus/lib/afl" \
    AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1 \
    AFL_SKIP_CPUFREQ=1 \
    ASAN_OPTIONS="abort_on_error=1:halt_on_error=1:print_stacktrace=1:detect_leaks=1:symbolize=1" \
    UBSAN_OPTIONS="print_stacktrace=1:halt_on_error=1" \
    TSAN_OPTIONS="halt_on_error=1:second_deadlock_stack=1" \
    ASAN_SYMBOLIZER_PATH="/usr/local/bin/llvm-symbolizer"

COPY config/42.bashrc /etc/profile.d/42-toolbox.sh
RUN echo '[ -f /etc/profile.d/42-toolbox.sh ] && . /etc/profile.d/42-toolbox.sh' >> /etc/bash.bashrc

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh \
 && rm -rf /usr/share/doc /usr/share/man /usr/share/info /tmp/scripts

WORKDIR /work
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["bash"]
