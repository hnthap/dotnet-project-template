SHELL           := /bin/bash
.SHELLFLAGS     := -euo pipefail -c
.DEFAULT_GOAL   := ci

SLN             ?= App.slnx
CONFIG          ?= Release
OUT             ?= artifacts

DOTNET          := dotnet
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_NOLOGO=1

.PHONY: ci tools restore licenses build test publish clean fmt fmt-check lockfiles

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
	$(DOTNET) build "$(SLN)" -c $(CONFIG) --no-restore

test: build
	$(DOTNET) test --solution "$(SLN)" -c $(CONFIG) --no-build \
		--results-directory "$(OUT)/test-results" \
		--report-xunit-trx --report-xunit-junit

publish: build
	$(DOTNET) publish src/Api/Api.csproj -c $(CONFIG) --no-build \
		-o "$(OUT)/publish"

clean:
	find . -type d \( -name bin -o -name obj \) -prune -exec rm -rf {} +
	rm -rf "$(OUT)"

fmt: tools
	$(DOTNET) tool run csharpier format .
	$(DOTNET) format style "$(SLN)"

fmt-check: tools restore
	$(DOTNET) tool run csharpier check .
	$(DOTNET) format style "$(SLN)" --verify-no-changes --no-restore
