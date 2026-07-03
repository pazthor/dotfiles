SHELL := /usr/bin/env bash

.PHONY: bootstrap adopt-config adopt-verify adot-config

# Link every repo-tracked config file into $HOME (idempotent).
bootstrap:
	./scripts/bootstrap $(ARGS)

# Import an existing home file into the repo (prints usage when run with no path).
adopt-config:
	./scripts/adopt-config $(ARGS)

# Preview canonical path mappings.
adopt-verify:
	./scripts/adopt-verify $(ARGS)

# Backward-compatible alias for the historical typo.
adot-config: adopt-config
	@echo "'adot-config' is deprecated; use 'adopt-config'."
