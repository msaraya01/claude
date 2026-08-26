# Requires: devcontainer CLI (npm i -g @devcontainers/cli), shellcheck
.PHONY: build test lint run coverage

SHELL_SCRIPTS := statusline-command.sh .devcontainer/setup.sh

build:
	devcontainer build --workspace-folder .

lint:
	shellcheck $(SHELL_SCRIPTS)

test: lint

run:
	devcontainer up --workspace-folder .

coverage:
	@echo "Config-only repo — no source code to measure."
