SHELL := /usr/bin/env bash

CHEZMOI ?= chezmoi
MIGRATION_MANIFEST ?= .cache/chezmoi-migration-manifest.txt

.PHONY: migrate-inventory migrate-import migrate-diff migrate-apply migrate-verify adopt-config adopt-verify adot-config

migrate-inventory:
	@mkdir -p "$(dir $(MIGRATION_MANIFEST))"
	@{ \
		git ls-files 'config/**' | sed "s#^config/#$$HOME/#"; \
		git ls-files '.config/**' | sed "s#^.config/#$$HOME/.config/#"; \
	} | sort -u > "$(MIGRATION_MANIFEST)"
	@echo "Wrote migration manifest: $(MIGRATION_MANIFEST)"
	@echo "Review and trim the file list before importing."

migrate-import: migrate-inventory
	@test -s "$(MIGRATION_MANIFEST)" || { echo "Manifest is empty: $(MIGRATION_MANIFEST)" >&2; exit 1; }
	@while IFS= read -r path; do \
		[[ -n "$$path" ]] || continue; \
		echo "Importing $$path"; \
		"$(CHEZMOI)" add --follow "$$path"; \
	done < "$(MIGRATION_MANIFEST)"

migrate-diff:
	@"$(CHEZMOI)" diff

migrate-apply:
	@"$(CHEZMOI)" apply

migrate-verify:
	@test -s "$(MIGRATION_MANIFEST)" || { echo "Run 'make migrate-inventory' first." >&2; exit 1; }
	@missing=0; non_symlink=0; \
	while IFS= read -r path; do \
		[[ -n "$$path" ]] || continue; \
		if [[ ! -e "$$path" && ! -L "$$path" ]]; then \
			echo "MISSING: $$path"; missing=$$((missing + 1)); \
		elif [[ ! -L "$$path" ]]; then \
			echo "NOT SYMLINK: $$path"; non_symlink=$$((non_symlink + 1)); \
		fi; \
	done < "$(MIGRATION_MANIFEST)"; \
	echo "Verification summary: missing=$$missing non_symlink=$$non_symlink"; \
	[[ $$missing -eq 0 && $$non_symlink -eq 0 ]]

adopt-config:
	./scripts/adopt-config

adopt-verify:
	./scripts/adopt-verify

# Backward-compatible alias for the historical typo.
adot-config: adopt-config
	@echo "'adot-config' is deprecated; use 'adopt-config'."
