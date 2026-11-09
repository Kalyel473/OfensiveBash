SHELL := /bin/bash

# Arquivos de shell do projeto (core, libs, modulos, entrypoint, install).
SH_FILES := ofensivabash install.sh \
	$(wildcard core/*.sh) \
	$(wildcard lib/*.sh) \
	$(wildcard modules/*/*.sh) \
	$(wildcard modules/*.sh)

.PHONY: install test lint fmt fmt-check run clean help

help:
	@echo "Alvos: install | test | lint | fmt | fmt-check | run | clean"

install:
	@bash install.sh

test:
	@if command -v bats >/dev/null 2>&1; then \
		bats tests/ ; \
	else \
		echo "bats nao instalado. Veja https://github.com/bats-core/bats-core" ; \
		exit 1 ; \
	fi

lint:
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck -x $(SH_FILES) && echo "ShellCheck: sem warnings." ; \
	else \
		echo "shellcheck nao instalado." ; exit 1 ; \
	fi

fmt:
	@if command -v shfmt >/dev/null 2>&1; then \
		shfmt -w -i 4 -ci $(SH_FILES) ; \
	else \
		echo "shfmt nao instalado." ; exit 1 ; \
	fi

fmt-check:
	@if command -v shfmt >/dev/null 2>&1; then \
		shfmt -d -i 4 -ci $(SH_FILES) ; \
	else \
		echo "shfmt nao instalado." ; exit 1 ; \
	fi

run:
	@bash ./ofensivabash

clean:
	@rm -rf workspaces/*/ 2>/dev/null || true
	@echo "workspaces limpos."
