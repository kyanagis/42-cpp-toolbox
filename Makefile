IMAGE    ?= ghcr.io/kyanagis/42-cpp-toolbox
TAG      ?= latest
PLATFORM ?= linux/amd64
RUNFLAGS  = --cap-add=SYS_PTRACE --security-opt seccomp=unconfined -v "$(PWD)":/work -w /work

.PHONY: help build push pull shell test lint clean

help:
	@echo "make build  - build $(IMAGE):$(TAG) for $(PLATFORM)"
	@echo "make push   - push to the registry (docker login ghcr.io first)"
	@echo "make pull   - pull $(IMAGE):$(TAG)"
	@echo "make shell  - interactive shell, CWD mounted at /work"
	@echo "make test   - run the smoke tests inside the image"
	@echo "make lint   - shellcheck + hadolint"

build:
	docker buildx build --platform $(PLATFORM) -t $(IMAGE):$(TAG) --load .

push:
	docker push $(IMAGE):$(TAG)

pull:
	docker pull $(IMAGE):$(TAG)

shell:
	docker run --rm -it $(RUNFLAGS) $(IMAGE):$(TAG)

test:
	docker run --rm $(RUNFLAGS) -v "$(PWD)/tests":/work $(IMAGE):$(TAG) bash /work/smoke/run.sh

lint:
	shellcheck --severity=warning scripts/*.sh config/gdb-gef config/gdb-pwndbg config/gdb-peda docker-entrypoint.sh run.sh tests/smoke/run.sh
	hadolint Dockerfile

clean:
	-docker rmi $(IMAGE):$(TAG)
