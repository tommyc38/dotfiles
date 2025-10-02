#!/bin/bash

# Pre-flight Check Script
# Verifies system requirements before running install.sh
# Run this before installation to catch potential issues early

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_check() {
    local status=$1
    local message=$2
    
    if [ "$status" = "pass" ]; then
        echo -e "${GREEN}✓${NC} $message"
        ((CHECKS_PASSED++))
    elif [ "$status" = "fail" ]; then
        echo -e "${RED}✗${NC} $message"
        ((CHECKS_FAILED++))
    elif [ "$status" = "warn" ]; then
        echo -e "${YELLOW}⚠${NC} $message"
        ((CHECKS_WARNING++))
    fi
}

check_macos() {
    print_header "System Requirements"
    
    # Check if running on macOS
    if [ "$(uname)" != "Darwin" ]; then
        print_check "fail" "Not running on macOS (detected: $(uname))"
        return 1
    fi
    print_check "pass" "Running on macOS"
    
    # Check macOS version
    local os_version=$(sw_vers -productVersion)
    print_check "pass" "macOS version: $os_version"
    
    # Check architecture
    local arch=$(uname -m)
    if [ "$arch" = "arm64" ]; then
        print_check "pass" "Architecture: Apple Silicon (arm64)"
    elif [ "$arch" = "x86_64" ]; then
        print_check "pass" "Architecture: Intel (x86_64)"
    else
        print_check "warn" "Unknown architecture: $arch"
    fi
}

check_disk_space() {
    print_header "Disk Space"
    
    # Check available disk space (in GB)
    local available=$(df -g / | awk 'NR==2 {print $4}')
    
    if [ "$available" -ge 10 ]; then
        print_check "pass" "Available disk space: ${available}GB (sufficient)"
    elif [ "$available" -ge 5 ]; then
        print_check "warn" "Available disk space: ${available}GB (may be tight)"
    else
        print_check "fail" "Available disk space: ${available}GB (insufficient, need at least 5GB)"
    fi
}

check_internet() {
    print_header "Network Connectivity"
    
    # Check internet connection
    if ping -c 1 -t 2 github.com >/dev/null 2>&1; then
        print_check "pass" "Internet connection active (github.com reachable)"
    else
        print_check "fail" "No internet connection (cannot reach github.com)"
    fi
    
    # Check if behind proxy
    if [ -n "$HTTP_PROXY" ] || [ -n "$HTTPS_PROXY" ]; then
        print_check "warn" "Proxy detected (HTTP_PROXY or HTTPS_PROXY set)"
    fi
}

check_xcode_cli() {
    print_header "Development Tools"
    
    # Check if Xcode CLI tools are installed
    if xcode-select -p >/dev/null 2>&1; then
        local xcode_path=$(xcode-select -p)
        print_check "pass" "Xcode Command Line Tools installed at: $xcode_path"
    else
        print_check "warn" "Xcode Command Line Tools not installed (install.sh will install them)"
    fi
}

check_homebrew() {
    # Check if Homebrew is installed
    if command -v brew >/dev/null 2>&1; then
        local brew_version=$(brew --version | head -n1)
        print_check "pass" "Homebrew installed: $brew_version"
        
        # Check Homebrew prefix
        local brew_prefix=$(brew --prefix 2>/dev/null)
        print_check "pass" "Homebrew prefix: $brew_prefix"
    else
        print_check "warn" "Homebrew not installed (install.sh will install it)"
    fi
}

check_shell() {
    print_header "Shell Configuration"
    
    # Check current shell
    local current_shell=$(echo $SHELL)
    print_check "pass" "Current shell: $current_shell"
    
    # Check if zsh is available
    if command -v zsh >/dev/null 2>&1; then
        local zsh_version=$(zsh --version)
        print_check "pass" "zsh available: $zsh_version"
    else
        print_check "warn" "zsh not found (included in macOS by default)"
    fi
    
    # Check if bash is available
    if command -v bash >/dev/null 2>&1; then
        local bash_version=$(bash --version | head -n1)
        print_check "pass" "bash available: $bash_version"
    fi
}

check_git() {
    # Check if git is installed
    if command -v git >/dev/null 2>&1; then
        local git_version=$(git --version)
        print_check "pass" "git installed: $git_version"
    else
        print_check "fail" "git not installed (required for installation)"
    fi
}

check_openssl() {
    # Check if openssl is available (needed for vault encryption)
    if command -v openssl >/dev/null 2>&1; then
        local openssl_version=$(openssl version)
        print_check "pass" "openssl available: $openssl_version"
    else
        print_check "fail" "openssl not found (required for vault encryption)"
    fi
}

check_permissions() {
    print_header "File Permissions"
    
    # Check if we have write access to home directory
    if [ -w "$HOME" ]; then
        print_check "pass" "Write access to home directory: $HOME"
    else
        print_check "fail" "No write access to home directory: $HOME"
    fi
    
    # Check if dotfiles directory exists and is writable
    if [ -d "$DOTFILES_DIR" ]; then
        if [ -w "$DOTFILES_DIR" ]; then
            print_check "pass" "Write access to dotfiles directory: $DOTFILES_DIR"
        else
            print_check "fail" "No write access to dotfiles directory: $DOTFILES_DIR"
        fi
    fi
    
    # Check if /usr/local is writable (for Intel Macs)
    if [ "$(uname -m)" = "x86_64" ]; then
        if [ -w "/usr/local" ]; then
            print_check "pass" "Write access to /usr/local"
        else
            print_check "warn" "No write access to /usr/local (may need sudo for Homebrew)"
        fi
    fi
}

check_existing_config() {
    print_header "Existing Configuration"
    
    # Check for existing dotfiles
    local existing_files=0
    for file in ~/.zshrc ~/.bashrc ~/.vimrc ~/.gitconfig; do
        if [ -f "$file" ]; then
            if [ -L "$file" ]; then
                print_check "pass" "$file exists (symlink)"
            else
                print_check "warn" "$file exists (will be backed up)"
                ((existing_files++))
            fi
        fi
    done
    
    if [ $existing_files -eq 0 ]; then
        print_check "pass" "No conflicting dotfiles found"
    fi
    
    # Check for existing ~/.workrc
    if [ -f "$HOME/.workrc" ]; then
        print_check "pass" "~/.workrc exists"
    else
        print_check "warn" "~/.workrc not found (will be created for workenv)"
    fi
}

check_vault_password() {
    print_header "Vault Configuration"
    
    # Remind about vault password requirement
    print_check "warn" "Vault password required as first argument to install.sh"
    
    # Check if vault directory exists
    if [ -d "$DOTFILES_DIR/vault" ]; then
        local vault_count=$(find "$DOTFILES_DIR/vault" -type f 2>/dev/null | wc -l | tr -d ' ')
        print_check "pass" "Vault directory exists with $vault_count encrypted files"
    else
        print_check "warn" "No vault directory found (optional)"
    fi
}

print_summary() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Pre-flight Check Summary${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}Passed: $CHECKS_PASSED${NC}"
    echo -e "${YELLOW}Warnings: $CHECKS_WARNING${NC}"
    echo -e "${RED}Failed: $CHECKS_FAILED${NC}"
    echo ""
    
    if [ $CHECKS_FAILED -eq 0 ]; then
        echo -e "${GREEN}✓ System ready for installation!${NC}"
        echo ""
        echo "Run installation with:"
        echo "  ./install.sh your_vault_password"
        echo ""
        return 0
    else
        echo -e "${RED}✗ System not ready - please fix failed checks${NC}"
        echo ""
        return 1
    fi
}

main() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   Dotfiles Pre-flight Check           ║${NC}"
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    
    check_macos
    check_disk_space
    check_internet
    check_xcode_cli
    check_homebrew
    check_shell
    check_git
    check_openssl
    check_permissions
    check_existing_config
    check_vault_password
    
    print_summary
}

main "$@"