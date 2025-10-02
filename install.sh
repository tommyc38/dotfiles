#!/bin/bash

# Exit on error, undefined variables, and pipe failures
set -e
set -u
set -o pipefail

script_path="$(dirname -- "$( readlink -f -- "$0")")"

# Error handler
trap 'echo "Error on line $LINENO. Exit code: $?" >&2' ERR

# Vault password is REQUIRED for initial setup
if [ $# -eq 0 ]; then
   echo "ERROR: Vault password is required as the first argument" >&2
   echo "Usage: ./install.sh <vault_password>" >&2
   exit 1
fi

VAULT_PASSWORD="$1"

# Verify we're on macOS
if [ "$(uname)" != "Darwin" ]; then
    echo "ERROR: This script is designed for macOS only" >&2
    exit 1
fi

# Do NOT run this script with sudo - we'll use sudo only when needed
if [ "$(id -u)" = 0 ]; then
   echo "ERROR: Do not run this script with sudo" >&2
   echo "The script will request sudo access only when needed (Xcode and shell setup)" >&2
   exit 1
fi

echo "========================================"
echo "Dotfiles Installation Starting"
echo "========================================"
echo ""

if [ "$(uname)" == "Darwin" ]; then
    echo "Running on macOS"

    # Check for Xcode Command Line Tools and install/update if needed
    echo "Checking Xcode Command Line Tools..."
    if ! xcode-select -p &>/dev/null; then
        echo "Installing Xcode Command Line Tools (requires sudo)..."
        sudo xcode-select --install
        echo "Please complete the Xcode installation dialog, then re-run this script"
        exit 0
    else
        echo "Xcode Command Line Tools already installed"
    fi

    echo "Installing System Packages & Desktop Applications..."
    sh install/brew.sh

    echo "Decrypting Vault Files..."
    # Ensure vault-key directory exists before decryption
    mkdir -p "$script_path/vault-key"
    sh bin/vault "$VAULT_PASSWORD"

    echo "Creating Dotfile Symlinks..."
    sh bin/symlink.sh -v -k

    echo "Processing Vault Symlinks..."
    # Check for vault-specific symlinks configuration
    if [ -f "$script_path/vault-key/symlinks.txt" ]; then
      sh bin/symlink.sh -f "$script_path/vault-key/symlinks.txt" -v
    else
      echo "No vault-key/symlinks.txt found, skipping vault symlinks"
    fi

    echo "Setting up SSH agent and keys..."
    if [ -f "$script_path/bin/ssh-setup.sh" ]; then
      sh "$script_path/bin/ssh-setup.sh"
    else
      echo "No SSH setup script found, skipping SSH agent setup"
    fi

    echo "Installing Node..."
    sh install/node.sh

    echo "Installing Python..."
    sh install/python.sh

    echo "Running Vault-Specific Installations..."
    if [ -e "$script_path/vault-key/install.sh" ]; then
      sh "$script_path/vault-key/install.sh"
    else
      echo "No vault-key/install.sh found, skipping"
    fi

    echo "Installing Fonts..."
    sh install/fonts.sh --google-fonts-light --nerd-fonts-light --powerline-fonts-light

    echo "Updating OSX settings"
    sh install/osx.sh

    echo "Setting ZSH as the Default Terminal"
    # Detect Homebrew prefix
    if [[ -x "/opt/homebrew/bin/brew" ]]; then
      HOMEBREW_PREFIX="/opt/homebrew"
    else
      HOMEBREW_PREFIX="/usr/local"
    fi
    
    # Add homebrew shells to /etc/shells (requires sudo)
    echo "Adding Homebrew shells to /etc/shells (requires sudo)..."
    grep -qxF "${HOMEBREW_PREFIX}/bin/bash" /etc/shells || echo "${HOMEBREW_PREFIX}/bin/bash" | sudo tee -a /etc/shells > /dev/null
    grep -qxF "${HOMEBREW_PREFIX}/bin/zsh" /etc/shells || echo "${HOMEBREW_PREFIX}/bin/zsh" | sudo tee -a /etc/shells > /dev/null
    
    # Change default shell to zsh
    echo "Changing default shell to zsh..."
    chsh -s "${HOMEBREW_PREFIX}/bin/zsh"

    echo "Installing Base16 Themes"
    [ ! -e ~/.config/base16-shell ] && git clone https://github.com/chriskempson/base16-shell.git ~/.config/base16-shell

    # Sourcing bash_profile before cloning repos
    echo "Loading shell configuration..."
    if [ -f ~/.bash_profile ]; then
        source ~/.bash_profile
    fi

    echo "Cloning Repositories..."
    # Find and process all .repos.txt files in vault-key
    if [ -d "$script_path/vault-key" ]; then
      find "$script_path/vault-key" -name "*.repos.txt" -type f | while read repos_file; do
        echo "Processing repositories from $(basename "$repos_file")..."
        sh bin/repo.sh --file "$repos_file" --default-directory "$HOME/dev" --npm-install
      done
    else
      echo "No .repos.txt files found in vault-key, skipping repository cloning"
    fi

fi

echo ""
echo "========================================"
echo "✅ Dotfiles Installation Complete!"
echo "========================================"
echo ""
echo "Next steps:"
echo "  1. Close and reopen your terminal (or run: source ~/.zshrc)"
echo "  2. Verify installation with: vault --help"
echo "  3. If you have a vault password, it should auto-load on next shell"
echo ""
echo "For help, see: ~/dotfiles/plan/README.md"
echo ""
