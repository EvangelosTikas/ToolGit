#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# ToolGit installation script
# Cross-platform installer (attempt) for Linux, macOS, and Windows Git Bash / WSL
# -----------------------------------------------------------------------------

set -euo pipefail


# ---------------------- Configuration ----------------------
INSTALL_DIR_DEFAULT="$HOME/.local/bin"
COMPLETIONS_DIR_BASH="$HOME/.local/share/bash-completion/completions"
COMPLETIONS_DIR_ZSH="$HOME/.oh-my-zsh/completions"

SCRIPT_NAME="git_helper"
BIN_PATH="./bin/$SCRIPT_NAME"
COMPLETIONS_PATH="./completions/$SCRIPT_NAME"


# ---------------------- Detect OS -------------------------
# TODO: which OS? 
OS="$(uname -s)"
case "$OS" in
    Linux*)   OS_TYPE=linux;;
    Darwin*)  OS_TYPE=mac;;
    CYGWIN*|MINGW*|MSYS*) OS_TYPE=windows;;
    *)        OS_TYPE=unknown;;
esac
echo "Detected OS: $OS_TYPE"

# ---------------------- Detect package managers -------------------------
has_cmd() { command -v "$1" >/dev/null 2>&1; }

# Determine preferred install dir
INSTALL_DIR="$INSTALL_DIR_DEFAULT"
mkdir -p "$INSTALL_DIR"

# ---------------------- Install executable -------------------------
echo "Installing $SCRIPT_NAME to $INSTALL_DIR..."
cp "$BIN_PATH" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

# ---------------------- Ensure PATH contains install dir -----------------
if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
    SHELL_RC="$HOME/.bashrc"
    [ -n "${ZSH_VERSION:-}" ] && SHELL_RC="$HOME/.zshrc"
    echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$SHELL_RC"
    echo "Added $INSTALL_DIR to PATH. Please restart your shell."
fi

# ---------------------- Install completions ----------------------------
if [ -f "$COMPLETIONS_PATH" ]; then
    case "$OS_TYPE" in
        linux|mac)
            mkdir -p "$COMPLETIONS_DIR_BASH"
            cp "$COMPLETIONS_PATH" "$COMPLETIONS_DIR_BASH/"
            echo "Installed bash completions to $COMPLETIONS_DIR_BASH"
            # zsh support
            mkdir -p "$COMPLETIONS_DIR_ZSH"
            cp "$COMPLETIONS_PATH" "$COMPLETIONS_DIR_ZSH/_$SCRIPT_NAME"
            echo "Installed zsh completions to $COMPLETIONS_DIR_ZSH"
            ;;
        windows)
            echo "Skipping completions on Windows Git Bash"
            ;;
    esac
fi

# ---------------------- Optional package manager integration -------------
# macOS: try brew
if [ "$OS_TYPE" = "mac" ] && has_cmd brew; then
    echo "macOS detected with Homebrew, optionally linking..."
    brew link --overwrite "$INSTALL_DIR/$SCRIPT_NAME" || true
fi

# ---------------------- Final message -------------------------------
echo "✅ $SCRIPT_NAME installed successfully!"
echo "Run: $SCRIPT_NAME --help"
echo "Or use: git $SCRIPT_NAME ..."
