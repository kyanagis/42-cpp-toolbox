# 42用のC/C++検証ツールをまとめたdocker image

C/C++の動的解析・静的解析・ファジング・対話的デバッグをdocker imageとして校舎の環境上で使えるようにする.
`linux/amd64` 

- ベース: Ubuntu 22.04 (jammy)
- 既定コンパイラ: `gcc`/`g++` → 12、`clang`/`clang++` → 14
  （IKOSがLLVM 14前提のため14を既定に.最新側は`clang-19` / `clang++-19`を併存）
- 配布先: `ghcr.io/kyanagis/42-cpp-toolbox:latest`

---

## クイックスタート

```bash
# 取得
docker pull ghcr.io/kyanagis/42-cpp-toolbox:latest

# カレントのコードを/workにマウントして対話シェル起動
IMAGE=ghcr.io/kyanagis/42-cpp-toolbox:latest ./run.sh

# 直接叩く場合
docker run --rm -it \
  --cap-add=SYS_PTRACE \
  --security-opt seccomp=unconfined \
  -v "$PWD":/work -w /work \
  ghcr.io/kyanagis/42-cpp-toolbox:latest
```

> `--cap-add=SYS_PTRACE --security-opt seccomp=unconfined`は
> gdb / valgrind /サニタイザを快適に使うために実質必須です。

---

## ぶち込んだツール

コンパイラ:
- gcc-11/12
- clang-14（既定）
- clang-19
- lld
- mold
- libc++ 14/19

ビルド:
- make
- cmake
- ninja
- meson
- autotools
- bear
- ccache
- compiledb

対話デバッグ:
- gdb + GEF(既定) / pwndbg / PEDA
- gdb-multiarch
- rr
- strace
- ltrace

サニタイザ:
- ASan / UBSan / TSan / MSan / LSan（gcc・clang両対応）
- llvm-symbolizer

動的解析/メモリ:
- valgrind(memcheck / helgrind / DRD / cachegrind / callgrind / massif / DHAT)
- heaptrack
- gperftools
- electric-fence
- DUMA

ファジング:
- libFuzzer
- AFL++(LTO / CMPLOG)
- honggfuzz
- radamsa

静的解析:
- clang-tidy(14/19)
- scan-build
- cppcheck(+htmlreport)
- IKOS v3.5
- Infer
- Frama-C
- IWYU
- CodeChecker
- semgrep
- flawfinder
- cpplint

カバレッジ:
- gcov
- lcov
- gcovr
- llvm-cov
- kcov

プロファイル/品質:
- callgrind
- gperftools(pprof)
- heaptrack
- hyperfine
- lizard(循環的複雑度)

バイナリ/リバース:
- binutils
- elfutils
- patchelf
- radare2
- checksec
- ROPgadget
- pwntools
- capstone
- pahole

テスト:
- GoogleTest / GMock
- Catch2
- doctest
- Criterion

便利系:
- vim
- neovim
- tmux
- ripgrep
- fd
- fzf
- jq
- bat
- htop
- ipython3
- universal-ctags

> Frama-Cはuniverse由来でベストエフォート導入（環境差で入らない場合はスキップ）
> `perf`は同梱していない（macOS/Docker DesktopのVMでは性能カウンタが使えないため）
> 起動シェルには`asan` `tsan` `msan` `vg` `vghel`等のエイリアスが定義済み.

---

## コマンド群

すべて`/work`（=ホストのカレントディレクトリ）上で実行する．

### サニタイザ
```bash
asan main.cpp -o app && ./app     # ASan + UBSan（= clang++ -std=c++20 -g -O1 -fsanitize=address,undefined）
tsan main.cpp -o app && ./app     # ThreadSanitizer（データ競合）
msan main.cpp -o app && ./app     # MemorySanitizer（※自己完結コード向け。後述の注意参照）
clang++ -std=c++20 -g -O1 -fsanitize=undefined main.cpp -o app && ./app   # UBSan単体
# gcc版サニタイザも利用可:
g++ -fsanitize=address,undefined -g main.cpp -o app && ./app
```

### 動的解析・メモリ（valgrindほか）
```bash
vg ./app                                  # memcheck（= --leak-check=full --show-leak-kinds=all --track-origins=yes）
vghel ./app                               # helgrind（データ競合）
valgrind --tool=drd ./app                 # DRD（スレッド誤用）
valgrind --tool=massif ./app              # massif（ヒープ推移）
valgrind --tool=cachegrind ./app          # cachegrind（キャッシュミス）
heaptrack ./app && heaptrack_print *.zst  # heaptrack（ヒープ割当）
LD_PRELOAD=libefence.so.0.0 ./app         # Electric Fence（境界外検出）
```

### 対話デバッグ
```bash
gdb ./app                #既定でGEFがロード
gdb-pwndbg ./app         # pwndbgで起動
gdb-peda ./app           # PEDAで起動
gdb-multiarch ./app      #クロスアーキ
strace -f ./app          #システムコールトレース
ltrace ./app             #ライブラリ呼び出しトレース
rr record ./app && rr replay   #逆再生デバッグ（VMでは不可の場合あり）
```

### 静的解析
```bash
bear -- make                           # compile_commands.jsonを生成
clang-tidy -p . src/*.cpp              # clang-tidy（14）。最新はclang-tidy-19
cppcheck --enable=all --inconclusive . # cppcheck
cppcheck --enable=all --xml . 2> r.xml && cppcheck-htmlreport --file=r.xml --report-dir=cppcheck-html
scan-build make                        # clang static analyzer
ikos main.cpp                          # IKOS（単一ファイル）
ikos-scan make                         # IKOS（ビルド全体）
infer run -- make                      # Facebook Infer
frama-c -eva main.c                    # Frama-C値解析（EVA）
include-what-you-use main.cpp          # IWYU
semgrep --config=auto .                # semgrep
flawfinder .                           # flawfinder
cpplint src/*.cpp                      # cpplint（スタイル）
lizard src/                            #循環的複雑度
```

### CodeChecker（解析結果をWeb UIに集約）
```bash
CodeChecker check -b "make" -o ./reports
CodeChecker server -w ./ws            # http://localhost:8001（-p 8001をdocker runで公開）
```

### ファジング
```bash
clang++ -fsanitize=fuzzer,address fuzz.cpp -o fuzz && ./fuzz   # libFuzzer
afl-cc -o tgt tgt.c && afl-fuzz -i in -o out -- ./tgt @@        # AFL++（in/に種ファイルを置く）
honggfuzz -i in -- ./tgt ___FILE___                            # honggfuzz
radamsa sample.txt > mutated.txt                               # radamsa（ブラックボックス変異）
```

### カバレッジ
```bash
clang++ --coverage main.cpp -o app && ./app
gcovr -r . --html-details cov.html     # gcovr（HTML）
lcov --capture --directory . --output-file cov.info && genhtml cov.info -o cov-html
kcov ./cov-out ./app                   #バイナリ実行のカバレッジ
```

### プロファイル
```bash
hyperfine './app arg1' './app arg2'        #ベンチ比較
valgrind --tool=callgrind ./app && callgrind_annotate callgrind.out.*
heaptrack ./app                            #ヒーププロファイル
```

### バイナリ/リバース
```bash
r2 -AA ./app                # radare2（解析付きで開く）
checksec --file=./app       #保護機構（RELRO/Canary/NX/PIE）
ROPgadget --binary ./app    # ROPガジェット
readelf -a ./app ; objdump -d ./app ; nm ./app
patchelf --print-needed ./app
pahole ./app                #構造体レイアウト
python3 -c 'from pwn import *; print(ELF("./app").checksec)'   # pwntools
```

### テスト
```bash
# GoogleTest（静的ライブラリはビルド済み）
g++ -std=c++20 test.cpp -lgtest -lgtest_main -pthread -o t && ./t
# Catch2 / doctestはヘッダで利用、Criterionは-lcriterion
```

---

## 起動オプションと制約

- 必須フラグ: `--cap-add=SYS_PTRACE --security-opt seccomp=unconfined`（gdb / valgrind /サニタイザ用）.
- CodeCheckerのWeb UIを見る場合: `-p 8001:8001`を追加.
- ファイル所有権: Docker Desktop for Macでは`/work`はホストユーザ所有のまま.
  ネイティブLinuxでは`-e HOST_UID=$(id -u) -e HOST_GID=$(id -g)`を付与.
- `perf` / `rr`:ハードウェア性能カウンタ依存でDocker DesktopのVMでは基本動きません.
  プロファイルはvalgrind callgrind/cachegrind・gperftools・heaptrack・hyperfineを使用.
- AFL++:コンテナ内では`core_pattern`を書けないため．
  `AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1` / `AFL_SKIP_CPUFREQ=1`を既定設定.
- MSan:標準ライブラリ含む全リンク対象をMSan計装しないと誤検知。自己完結コードなら可.

---

## バージョン固定（Dockerfile冒頭の`ARG`）

| ツール | 既定 |
|--------|------|
| IKOS | `v3.5` |
| AFL++ | `v4.40c` |
| honggfuzz | `master @ 48790f7`（2.6タグはbinutils 2.39のstyled disassembler非対応のため）|
| radamsa | `v0.7` |
| radare2 | `6.1.4` |
| pwndbg | `2026.02.18` |
| LLVM(最新側) | `19` |
| Infer | `1.2.0`（→`1.1.0`フォールバック。`1.3.0`はglibc≥2.38要求でjammy非対応）|

変更例: `docker buildx build --build-arg LLVM_MODERN=20 ...`

---

## ビルド/配布

```bash
# ビルド（自宅or CI）
make build IMAGE=ghcr.io/kyanagis/42-cpp-toolbox
# = docker buildx build --platform linux/amd64 -t ghcr.io/kyanagis/42-cpp-toolbox:latest --load .

# GHCRへpush
echo $CR_PAT | docker login ghcr.io -u kyanagis --password-stdin
make push IMAGE=ghcr.io/kyanagis/42-cpp-toolbox

# ローカルのスモークテスト
make test
# 静的チェック
make lint   # shellcheck + hadolint
```
