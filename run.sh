#!/usr/bin/env bash
set -euo pipefail

IMAGE="${IMAGE:-ghcr.io/kyanagis/42-cpp-toolbox:latest}"

exec docker run --rm -it \
  --cap-add=SYS_PTRACE \
  --security-opt seccomp=unconfined \
  -v "$PWD":/work -w /work \
  "$IMAGE" "$@"
