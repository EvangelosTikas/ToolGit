# Makefile for git-helper
# ---------------------------------------
# Install paths (user-local by default)
PREFIX ?= $(HOME)/.local
BIN_DIR := $(PREFIX)/bin
LIB_DIR := $(PREFIX)/lib/git_helper
TOOL_NAME := git_helper
VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")

# ---------------------------------------
# Default target
.PHONY: all
all: help

# ---------------------------------------
# Installation
.PHONY: install
install:
	@echo "Installing $(TOOL_NAME) version $(VERSION) to $(PREFIX)"
	mkdir -p $(BIN_DIR) $(LIB_DIR)
	cp -f bin/git_helper.sh $(LIB_DIR)/
	cp -f bin/git_helper $(BIN_DIR)/
	chmod +x $(BIN_DIR)/git_helper
	@echo "✅ Installed to $(BIN_DIR)"
	@echo "Version: $(VERSION)"

# ---------------------------------------
# Uninstall
.PHONY: uninstall
uninstall:
	@echo "Removing $(TOOL_NAME) from $(PREFIX)"
	rm -f $(BIN_DIR)/git_helper
	rm -rf $(LIB_DIR)
	@echo "✅ Uninstalled."

# ---------------------------------------
# Development helpers
.PHONY: lint
lint:
	@echo "Running shellcheck..."
	shellcheck bin/*.sh

.PHONY: tag
tag:
	@read -p "Enter new version tag (e.g. v1.0.0): " TAG; \
	git tag -a $$TAG -m "Release $$TAG"; \
	git push origin $$TAG; \
	echo "✅ Tagged and pushed $$TAG"

verify_install:
	which git_helper
	git_helper --version

.PHONY: help
help:
	@echo "Available targets:"
	@echo "  make install    - Install locally under $(PREFIX)"
	@echo "  make uninstall  - Remove installed files"
	@echo "  make lint       - Run shellcheck on all scripts"
	@echo "  make tag        - Create and push a new git tag"

