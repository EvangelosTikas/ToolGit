# ==============================================
# Makefile for ToolGit
# Cross-platform installer using Go
# ==============================================

SHELL := /usr/bin/env bash
PREFIX ?= $(HOME)/.local
BIN_DIR := $(PREFIX)/bin
LIB_DIR := $(PREFIX)/lib/ToolGit
TOOL_NAME := ToolGit
VERSION := $(shell cat VERSION 2>/dev/null || echo "dev")

GO := go

.PHONY: all build install uninstall clean cross

# Default: show help
all: help

# ===============================
# Build the installer for current OS
build:
	@echo "🛠 Building installer for current OS..."
	$(GO) build -o $(BIN_DIR)/ToolGit-install cmd/install.go
	@echo "✅ Built: $(BIN_DIR)/ToolGit-install"

# ===============================
# Build cross-platform installers
cross:
	@echo "🌐 Building cross-platform binaries..."
	GOOS=linux GOARCH=amd64 $(GO) build -o ToolGit-install-linux cmd/install.go
	GOOS=darwin GOARCH=amd64 $(GO) build -o ToolGit-install-macos cmd/install.go
	GOOS=windows GOARCH=amd64 $(GO) build -o ToolGit-install.exe cmd/install.go
	@echo "✅ Cross-platform binaries ready"

# ===============================
# Install ToolGit using Go installer
install:
	@echo "🔧 Installing $(TOOL_NAME)..."
	@mkdir -p $(BIN_DIR)
	@chmod +x $(BIN_DIR)/ToolGit-install || true
	@$(BIN_DIR)/ToolGit-install
	@echo "✅ $(TOOL_NAME) installed. Make sure $(BIN_DIR) is in your PATH."

# ===============================
# Uninstall ToolGit
uninstall:
	@echo "🧹 Uninstalling $(TOOL_NAME)..."
	@rm -rf $(LIB_DIR)
	@rm -f $(BIN_DIR)/ToolGit-install
	@ls $(BIN_DIR) | grep '^gh_' | xargs -I{} rm -f $(BIN_DIR)/{}
	@echo "✅ $(TOOL_NAME) and gh_* commands removed"

# ===============================
# Lint bash scripts
lint:
	@shellcheck bin/*.sh || true
	@echo "✅ Lint done"

# ===============================
# Clean build artifacts
clean:
	@rm -f $(BIN_DIR)/ToolGit-install
	@rm -f ToolGit-install-linux ToolGit-install-macos ToolGit-install.exe
	@echo "🧹 Cleaned build artifacts"

# ===============================
# Final step
release: cross
	@mkdir -p release
	cp bin/git_helpers.sh release/
	cp ToolGit-install-linux release/
	cp ToolGit-install-macos release/
	cp ToolGit-install.exe release/
	@cd release && zip -r ToolGit-release-v$(VERSION).zip *
	@echo "✅ Release archive ready: release/ToolGit-release-v$(VERSION).zip"

# ===============================
# Help
help:
	@echo "📘 ToolGit Makefile Targets:"
	@echo "  make build       - Build installer for current OS"
	@echo "  make cross       - Build cross-platform installers"
	@echo "  make install     - Run installer (produces gh_* commands)"
	@echo "  make uninstall   - Remove ToolGit and gh_* commands"
	@echo "  make lint        - Run shellcheck on helpers"
	@echo "  make clean       - Remove build artifacts"
	@echo "  make help        - Show this help"
