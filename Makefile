# ==============================================
# Makefile for ToolGit
# App: [ToolGit]
# Description: An exclusive CLI/wrapper application to wrap every version control job
# in a pretty toolbox
# Author : Evangelos Tikas
# License: MIT License
#
# Copyright (c) 2025 EVANGELOS TIKAS
#
# ==============================================

SHELL := /usr/bin/env bash
PREFIX ?= $(HOME)/.local
BIN_DIR := $(PREFIX)/bin
LIB_DIR := $(PREFIX)/lib/ToolGit
TOOL_NAME := ToolGit
VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
VERSION_FILE := VERSION

# ==============================================
.PHONY: all install uninstall lint test test-bats tag help ci

all: help

install:
	@echo "🔧 Installing $(TOOL_NAME) $(VERSION) under $(PREFIX)"
	@mkdir -p "$(BIN_DIR)" "$(LIB_DIR)"
	cp -f bin/git_helpers.sh "$(LIB_DIR)/"
	cp -f bin/ToolGit "$(BIN_DIR)/"
	chmod +x "$(BIN_DIR)/ToolGit"
	echo "$(VERSION)" > $(VERSION_FILE)
	@echo "✅ Installed $(TOOL_NAME) → $(BIN_DIR)/ToolGit"
	@printf "[\033[94mToolGit\033[0m]\n"
	@printf "[\033[94m <<< WELCOME! >>> \033[0m]\n"

uninstall:
	@echo "🧹 Removing $(TOOL_NAME)..."
	rm -f "$(BIN_DIR)/ToolGit"
	rm -rf "$(LIB_DIR)"
	rm -f $(VERSION_FILE)
	@echo "✅ Uninstalled $(TOOL_NAME)"


lint:
	@echo "🔍 Running ShellCheck..."
	shellcheck bin/*.sh || true
	@echo "✅ Lint check done."

check-cli:
	@echo "Testing CLI basic operations..."
	$(BIN_DIR)/ToolGit --help >/dev/null
	@echo "PASS: CLI help command successful"
	$(BIN_DIR)/ToolGit --version
	@echo "PASS: CLI version command successful"

test-bats:
	@echo "🧪 Running Bats tests..."
	@if ! command -v bats &>/dev/null; then \
		echo "📦 Installing local Bats..."; \
		git clone --depth=1 https://github.com/bats-core/bats-core.git /tmp/bats-core >/dev/null; \
		sudo /tmp/bats-core/install.sh /usr/local >/dev/null; \
	fi
	bats tests/

tag:
	@read -p "Enter new version tag (e.g. v1.0.0): " TAG; \
	git tag -a $$TAG -m "Release $$TAG"; \
	git push origin $$TAG; \
	echo "✅ Tagged $$TAG"

help:
	@echo "📘 Available targets:"
	@echo "  make install     - Install ToolGit"
	@echo "  make uninstall   - Remove ToolGit"
	@echo "  make lint        - Run ShellCheck"
	@echo "  make check-cli   - Run basic CLI tests"
	@echo "  make test-bats   - Run Bats tests in tests/"
	@echo "  make tag         - Create and push version tag"
	@echo "  make help        - Show this help"


