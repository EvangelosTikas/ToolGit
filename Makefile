# ==============================================
# Makefile for ToolGit
# ==============================================

PREFIX ?= $(HOME)/.local
BIN_DIR := $(PREFIX)/bin
LIB_DIR := $(PREFIX)/lib/ToolGit
TOOL_NAME := ToolGit
VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")

# ==============================================
.PHONY: all
all: help

# ==============================================
.PHONY: install
install:
	@echo "🔧 Installing $(TOOL_NAME) version $(VERSION) into $(PREFIX)"
	@if [ ! -d "$(BIN_DIR)" ]; then \
		echo "📁 Creating $(BIN_DIR)"; \
		mkdir -p "$(BIN_DIR)"; \
	fi
	@if [ ! -d "$(LIB_DIR)" ]; then \
		echo "📁 Creating $(LIB_DIR)"; \
		mkdir -p "$(LIB_DIR)"; \
	fi
	@cp -f bin/git_helpers.sh "$(LIB_DIR)/"
	@if [ -f bin/ToolGit ]; then \
		echo "📄 Found CLI wrapper bin/ToolGit"; \
		cp -f bin/ToolGit "$(BIN_DIR)/"; \
		chmod +x "$(BIN_DIR)/ToolGit"; \
		echo "✅ Installed executable: $(BIN_DIR)/ToolGit"; \
	else \
		echo "⚠️  No CLI wrapper found (bin/ToolGit). Only the library was installed."; \
	fi
	@echo "✅ Library installed at: $(LIB_DIR)/git_helpers.sh"
	@echo "ℹ️  Version: $(VERSION)"

# ==============================================
.PHONY: uninstall
uninstall:
	@echo "🧹 Removing $(TOOL_NAME) from $(PREFIX)"
	@rm -f "$(BIN_DIR)/ToolGit"
	@rm -rf "$(LIB_DIR)"
	@echo "✅ Uninstalled $(TOOL_NAME)."

# ==============================================
.PHONY: lint
lint:
	@echo "🔍 Running shellcheck..."
	shellcheck bin/*.sh || true

# ==============================================
.PHONY: tag
tag:
	@read -p "Enter new version tag (e.g. v1.0.0): " TAG; \
	git tag -a $$TAG -m "Release $$TAG"; \
	git push origin $$TAG; \
	echo "✅ Tagged and pushed $$TAG"

# ==============================================
.PHONY: ver_install
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

