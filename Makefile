SHELL           := /bin/bash
.SHELLFLAGS     := -euo pipefail -c
.DEFAULT_GOAL   := ci

SLN             ?= App.slnx
CONFIG          ?= Release
OUT             ?= artifacts

# From the newest v* git tag: 1.2.0 on the tag itself, 1.2.0-5-g789abcd five
# commits later, with -dirty for uncommitted changes; 0.0.0-<commits>-g<sha>
# before the first tag. Goes into the assemblies and is the image tag.
ifndef VERSION
VERSION := $(shell \
	d=$$(git describe --tags --match 'v[0-9]*' --dirty 2>/dev/null) && echo "$${d#v}" \
	|| echo "0.0.0-$$(git rev-list --count HEAD)-g$$(git describe --always --dirty)")
endif

# Container image: CI sets the registry and repository (see .gitlab-ci.yml)
IMAGE_REGISTRY  ?=
IMAGE_REPOSITORY ?= api
IMAGE_TAG       ?= $(VERSION)

DOTNET          := dotnet
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_NOLOGO=1

# The .NET SDK builds the image itself (no Dockerfile or container engine), on
# mcr.microsoft.com/dotnet/aspnet matching the target framework
PUBLISH_IMAGE   = $(DOTNET) publish src/Api/Api.csproj -c $(CONFIG) --no-build \
	-p:Version="$(VERSION)" \
	-t:PublishContainer \
	-p:ContainerRepository="$(IMAGE_REPOSITORY)" \
	-p:ContainerImageTag="$(IMAGE_TAG)"

.PHONY: ci tools restore licenses build test publish image image-push clean fmt fmt-check lockfiles

ci: lockfiles fmt-check licenses build test publish

tools:
	$(DOTNET) tool restore

restore:
	$(DOTNET) restore "$(SLN)" --locked-mode

lockfiles: restore
	@git rev-parse --is-inside-work-tree >/dev/null
	@if [ -n "$$(git status --porcelain -- '*packages.lock.json')" ]; then \
		echo "error: lock files not committed:"; \
		git status --short -- '*packages.lock.json'; \
		exit 1; \
	fi

licenses: tools restore
	mkdir -p "$(OUT)"
	$(DOTNET) tool run nuget-license \
		-i "$(SLN)" \
		-t \
		-a allowed-licenses.json \
		-o JsonPretty > "$(OUT)/licenses.json"

build: restore
	$(DOTNET) build "$(SLN)" -c $(CONFIG) --no-restore -p:Version="$(VERSION)"

test: build
	$(DOTNET) test --solution "$(SLN)" -c $(CONFIG) --no-build \
		--results-directory "$(OUT)/test-results" \
		--report-xunit-trx --report-xunit-junit

publish: build
	$(DOTNET) publish src/Api/Api.csproj -c $(CONFIG) --no-build \
		-p:Version="$(VERSION)" -o "$(OUT)/publish"

image: build
	mkdir -p "$(OUT)"
	$(PUBLISH_IMAGE) -p:ContainerArchiveOutputPath="$(CURDIR)/$(OUT)/image.tar.gz"

image-push: build
	@test -n "$(IMAGE_REGISTRY)" || { echo "error: set IMAGE_REGISTRY"; exit 1; }
	$(PUBLISH_IMAGE) -p:ContainerRegistry="$(IMAGE_REGISTRY)"

clean:
	find . -type d \( -name bin -o -name obj \) -prune -exec rm -rf {} +
	rm -rf "$(OUT)"

fmt: tools
	$(DOTNET) tool run csharpier format .
	$(DOTNET) format style "$(SLN)"

fmt-check: tools restore
	$(DOTNET) tool run csharpier check .
	$(DOTNET) format style "$(SLN)" --verify-no-changes --no-restore
