#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")" || exit 1

fail=0
pass() { printf '  \033[32mok\033[0m   %s\n' "$1"; }
miss() { printf '  \033[31mMISS\033[0m %s\n' "$1"; fail=1; }
soft() { printf '  \033[33mskip\033[0m %s\n' "$1"; }
note() { printf '\n\033[1m== %s ==\033[0m\n' "$1"; }
detect() { # $1=label $2=ERE pattern $3=output file
  if grep -qiE "$2" "$3"; then pass "$1"; else miss "$1"; tail -8 "$3" | sed 's/^/      | /'; fi
}

note "tool presence"
TOOLS="gcc-12 g++-12 clang-14 clang++-14 clang-19 cc c++ gdb gdb-gef gdb-pwndbg
       gdb-peda rr strace ltrace valgrind heaptrack google-pprof
       cmake ninja meson bear ccache mold hyperfine
       cppcheck clang-tidy clang-format scan-build include-what-you-use
       ikos ikos-scan infer afl-fuzz afl-cc afl-clang-lto honggfuzz radamsa
       libfuzzer-check lcov gcovr kcov llvm-cov-14
       radare2 patchelf checksec ROPgadget readelf objdump nm
       pahole ctags lizard
       semgrep cpplint flawfinder CodeChecker compiledb"
for t in $TOOLS; do
  case "$t" in
    libfuzzer-check)
      echo 'int LLVMFuzzerTestOneInput(const unsigned char*x,unsigned long n){return 0;}' > /tmp/f.c
      if clang -fsanitize=fuzzer /tmp/f.c -o /tmp/f 2>/dev/null; then pass "libFuzzer (-fsanitize=fuzzer)"; else miss "libFuzzer"; fi ;;
    *) if command -v "$t" >/dev/null 2>&1; then pass "$t"; else miss "$t"; fi ;;
  esac
done
if python3 -c 'import pwn' 2>/dev/null; then pass "pwntools (import pwn)"; else miss "pwntools"; fi

note "optional tools (best-effort, non-fatal)"
for t in lldb-14 frama-c cppcheck-htmlreport one_gadget; do
  if command -v "$t" >/dev/null 2>&1; then pass "$t"; else soft "$t (not installed)"; fi
done

note "ASan / UBSan — leak.cpp"
{ clang++ -std=c++20 -g -O1 -fno-omit-frame-pointer -fsanitize=address,undefined leak.cpp -o /tmp/leak && /tmp/leak; } >/tmp/o 2>&1
detect "ASan detected overflow/leak" 'heap-buffer-overflow|AddressSanitizer' /tmp/o

note "ThreadSanitizer — race.cpp"
{ clang++ -std=c++20 -g -O1 -fsanitize=thread race.cpp -o /tmp/race && /tmp/race; } >/tmp/o 2>&1
detect "TSan detected data race" 'ThreadSanitizer' /tmp/o

note "UBSan — ub.cpp"
{ clang++ -std=c++20 -g -O1 -fsanitize=undefined ub.cpp -o /tmp/ub && /tmp/ub; } >/tmp/o 2>&1
detect "UBSan detected signed overflow" 'runtime error' /tmp/o

note "valgrind memcheck — leak.cpp"
{ clang++ -std=c++20 -g -O0 leak.cpp -o /tmp/leakv && valgrind --leak-check=full /tmp/leakv; } >/tmp/o 2>&1
detect "valgrind flagged the bug" 'invalid write|definitely lost' /tmp/o

note "cppcheck — null.c"
cppcheck --enable=all --error-exitcode=0 null.c >/tmp/o 2>&1
detect "cppcheck produced findings" 'null|leak|error|uninit' /tmp/o

note "clang-tidy — null.c"
clang-tidy null.c -- -std=c11 >/tmp/o 2>&1 || true
detect "clang-tidy ran" 'warning|note' /tmp/o

note "IKOS — null.c"
ikos null.c -o /tmp/null.db >/tmp/o 2>&1 || true
detect "ikos analyzed null.c" 'safe|warning|error|unreachable' /tmp/o

note "Infer — null.c"
infer run --no-progress-bar -- clang -c null.c >/tmp/o 2>&1 || true
detect "infer ran" 'analyz|report|issue|found|NULL|RACE' /tmp/o

echo
if [ "$fail" = 0 ]; then printf '\033[32mALL SMOKE CHECKS PASSED\033[0m\n'; else printf '\033[31mSOME CHECKS FAILED — see MISS lines above\033[0m\n'; fi
exit "$fail"
