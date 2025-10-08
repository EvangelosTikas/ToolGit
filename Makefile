# ==============================================
# Makefile for ToolGit
# ==============================================
# User-local installation by default (no sudo)
PREFIX ?= $(HOME)/.local
BIN_DIR := $(PREFIX)/bin
LIB_DIR := $(PREFIX)/lib/ToolGit
TOOL_NAME := ToolGit
VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")

# ==============================================
# Default target
.PHONY: all
all: help

# ==============================================
# Installation
.PHONY: install
install:
	@echo "🔧 Installing $(TOOL_NAME) version $(VERSION) to $(PREFIX)"
	mkdir -p $(BIN_DIR) $(LIB_DIR)
	cp -f bin/git_helpers.sh $(LIB_DIR)/
	@if [ -f bin/ToolGit ]; then \
		cp -f bin/ToolGit $(BIN_DIR)/; \
		chmod +x $(BIN_DIR)/ToolGit; \
		echo "✅ Installed CLI wrapper: $(BIN_DIR)/ToolGit"; \
	else \
		echo "⚠️  No CLI wrapper (bin/ToolGit) found — only library installed."; \
	fi
	@echo "✅ Library installed to $(LIB_DIR)"
	@echo "Version: $(VERSION)"

# ==============================================
# Uninstall
.PHONY: uninstall
uninstall:
	@echo "🧹 Removing $(TOOL_NAME) from $(PREFIX)"
	rm -f $(BIN_DIR)/ToolGit
	rm -rf $(LIB_DIR)
	@echo "✅ Uninstalled $(TOOL_NAME)."

# ==============================================
# Linting (for developers)
.PHONY: lint
lint:
	@echo "🔍 Running shellcheck..."
	shellcheck bin/*.sh || true

# ==============================================
# Tag a new version
.PHONY: tag
tag:
	@read -p "Enter new version tag (e.g. v1.0.0): " TAG; \
	git tag -a $$TAG -m "Release $$TAG"; \
	git push origin $$TAG; \
	echo "✅ Tagged and pushed $$TAG"

ver_install:
	which ToolGit
	ToolGit --version

# ==============================================
# Help
.PHONY: help
help:
	@echo "📘 Available targets:"
	@echo "  make install     - Install ToolGit under $(PREFIX)"
	@echo "  make uninstall   - Remove installed ToolGit files"
	@echo "  make lint        - Run shellcheck on all scripts"
	@echo "  make tag         - Create and push a new git tag"
	@echo "  make help        - Show this message"
	@echo "  make ver_install - Verify installation"

