case ":$PATH:" in
  *":/opt/ikos/bin:"*) ;;
  *) export PATH="/opt/ikos/bin:/opt/infer/bin:/opt/aflplusplus/bin:/opt/radamsa/bin:/opt/honggfuzz/bin:$PATH" ;;
esac

export ASAN_OPTIONS="${ASAN_OPTIONS:-abort_on_error=1:halt_on_error=1:print_stacktrace=1:detect_leaks=1:symbolize=1}"
export UBSAN_OPTIONS="${UBSAN_OPTIONS:-print_stacktrace=1:halt_on_error=1}"
export TSAN_OPTIONS="${TSAN_OPTIONS:-halt_on_error=1:second_deadlock_stack=1}"
export ASAN_SYMBOLIZER_PATH="${ASAN_SYMBOLIZER_PATH:-/usr/local/bin/llvm-symbolizer}"

# AFL_SKIP_CPUFREQ/AFL_I_DONT_CARE_ABOUT_MISSING_CRASHESはコンテナ内（/proc/sys読取専用）向け。https://github.com/AFLplusplus/AFLplusplus/blob/stable/docs/env_variables.md
export AFL_PATH="${AFL_PATH:-/opt/aflplusplus/lib/afl}"
export AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1
export AFL_SKIP_CPUFREQ=1

command -v batcat >/dev/null 2>&1 && alias bat='batcat'
command -v fdfind >/dev/null 2>&1 && alias fd='fdfind'
alias ll='ls -alFh --color=auto'
alias asan='clang++ -std=c++20 -g -O1 -fno-omit-frame-pointer -fsanitize=address,undefined'
alias tsan='clang++ -std=c++20 -g -O1 -fsanitize=thread'
alias msan='clang++ -std=c++20 -g -O1 -fsanitize=memory -fno-omit-frame-pointer'
alias vg='valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes'
alias vghel='valgrind --tool=helgrind'

if [ -n "${BASH_VERSION:-}" ]; then
  PS1='\[\e[38;5;39m\]42cpp\[\e[0m\]:\[\e[38;5;249m\]\w\[\e[0m\]\$ '
fi
