#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")" || exit 1

fail=0
pass() { printf '  \033[32mok\033[0m   %s\n' "$1"; }
miss() { printf '  \033[31mMISS\033[0m %s\n' "$1"; fail=1; }
soft() { printf '  \033[33mskip\033[0m %s\n' "$1"; }
note() { printf '\n\033[1m== %s ==\033[0m\n' "$1"; }

note "tool presence"
TOOLS="gcc-12 g++-12 clang-14 clang++-14 clang-19 cc c++ gdb gdb-gef gdb-pwndbg
       gdb-peda lldb-14 rr strace ltrace valgrind heaptrack google-pprof
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
for t in frama-c cppcheck-htmlreport one_gadget; do
  if command -v "$t" >/dev/null 2>&1; then pass "$t"; else soft "$t (not installed)"; fi
done

note "ASan / UBSan — leak.cpp"
clang++ -std=c++20 -g -O1 -fsanitize=address,undefined leak.cpp -o /tmp/leak 2>/dev/null
if /tmp/leak 2>&1 | grep -qiE 'heap-buffer-overflow|AddressSanitizer'; then pass "ASan detected overflow/leak"; else miss "ASan detection"; fi

note "ThreadSanitizer — race.cpp"
clang++ -std=c++20 -g -O1 -fsanitize=thread race.cpp -o /tmp/race 2>/dev/null
if /tmp/race 2>&1 | grep -qi 'ThreadSanitizer'; then pass "TSan detected data race"; else miss "TSan detection"; fi

note "UBSan — ub.cpp"
clang++ -std=c++20 -g -O1 -fsanitize=undefined ub.cpp -o /tmp/ub 2>/dev/null
if /tmp/ub 2>&1 | grep -qi 'runtime error'; then pass "UBSan detected signed overflow"; else miss "UBSan detection"; fi

note "valgrind memcheck — leak.cpp"
clang++ -std=c++20 -g -O0 leak.cpp -o /tmp/leakv 2>/dev/null
if valgrind --error-exitcode=42 --leak-check=full /tmp/leakv 2>&1 | grep -qiE 'invalid write|definitely lost'; then pass "valgrind flagged the bug"; else miss "valgrind detection"; fi

note "cppcheck — null.c"
if cppcheck --enable=all --error-exitcode=0 null.c 2>&1 | grep -qiE 'null|leak|error'; then pass "cppcheck produced findings"; else miss "cppcheck findings"; fi

note "clang-tidy — null.c"
clang-tidy null.c -- -std=c11 >/tmp/tidy.txt 2>&1 || true
if grep -qiE 'warning|note' /tmp/tidy.txt; then pass "clang-tidy ran"; else miss "clang-tidy run"; fi

note "IKOS — null.c"
if ikos null.c -o /tmp/null.db >/tmp/ikos.txt 2>&1 && grep -qiE 'safe|warning|error|unreachable' /tmp/ikos.txt; then pass "ikos analyzed null.c"; else miss "ikos analysis"; fi

note "Infer — null.c"
if infer run --no-progress-bar -- clang -c null.c >/tmp/infer.txt 2>&1; then pass "infer ran (see report)"; else miss "infer run"; fi

echo
if [ "$fail" = 0 ]; then printf '\033[32mALL SMOKE CHECKS PASSED\033[0m\n'; else printf '\033[31mSOME CHECKS FAILED — see MISS lines above\033[0m\n'; fi
exit "$fail"
