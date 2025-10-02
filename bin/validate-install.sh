#!/bin/bash

# Post-Installation Validation Script
# Verifies that install.sh completed successfully
# Run this after installation to confirm everything is set up correctly

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

validate_homebrew() {
    print_header "Homebrew Installation"
    
    if command -v brew >/dev/null 2>&1; then
        print_check "pass" "Homebrew is installed"
        
        # Check brew doctor
        if brew doctor >/dev/null 2>&1; then
            print_check "pass" "Homebrew health check passed"
        else
            print_check "warn" "Homebrew reports warnings (run 'brew doctor' for details)"
        fi
        
        # Check for common packages
        local packages=("git" "zsh" "vim" "tmux" "openssl")
        for pkg in "${packages[@]}"; do
            if brew list "$pkg" >/dev/null 2>&1; then
                print_check "pass" "$pkg installed via Homebrew"
            else
                print_check "warn" "$pkg not installed"
            fi
        done
    else
        print_check "fail" "Homebrew not installed"
    fi
}

validate_vault() {
    print_header "Vault System"
    
    # Check if vault-key directory exists
    if [ -d "$DOTFILES_DIR/vault-key" ]; then
        print_check "pass" "vault-key directory exists"
        
        # Check for password.txt
        if [ -f "$DOTFILES_DIR/vault-key/password.txt" ]; then
            print_check "pass" "Vault password file exists"
            
            # Check if VAULT_PASSWORD is set
            if [ -n "$VAULT_PASSWORD" ]; then
                print_check "pass" "VAULT_PASSWORD environment variable is set"
            else
                print_check "warn" "VAULT_PASSWORD not set (may need to source shell config)"
            fi
        else
            print_check "warn" "password.txt not found (vault may not be decrypted)"
        fi
    else
        print_check "warn" "vault-key directory not found (vault may not be used)"
    fi
}

validate_symlinks() {
    print_header "Symlink Configuration"
    
    # Check critical symlinks
    local symlinks=(
        "$HOME/.zshrc"
        "$HOME/.bashrc"
        "$HOME/.vimrc"
    )
    
    for link in "${symlinks[@]}"; do
        if [ -L "$link" ]; then
            local target=$(readlink "$link")
            print_check "pass" "$(basename $link) → $target"
        elif [ -f "$link" ]; then
            print_check "warn" "$(basename $link) exists but is not a symlink"
        else
            print_check "fail" "$(basename $link) not found"
        fi
    done
    
    # Check .workrc for workenv
    if [ -L "$HOME/.workrc" ] || [ -f "$HOME/.workrc" ]; then
        print_check "pass" ".workrc exists (required for workenv)"
    else
        print_check "warn" ".workrc not found (workenv may not function)"
    fi
}

validate_ssh() {
    print_header "SSH Configuration"
    
    # Check SSH directory
    if [ -d "$HOME/.ssh" ]; then
        print_check "pass" "~/.ssh directory exists"
        
        # Check SSH directory permissions
        local ssh_perms=$(stat -f "%A" "$HOME/.ssh" 2>/dev/null || stat -c "%a" "$HOME/.ssh" 2>/dev/null)
        if [ "$ssh_perms" = "700" ]; then
            print_check "pass" "~/.ssh permissions correct (700)"
        else
            print_check "warn" "~/.ssh permissions: $ssh_perms (should be 700)"
        fi
        
        # Check for SSH keys
        local key_count=$(find "$HOME/.ssh" -name "*.pub" 2>/dev/null | wc -l | tr -d ' ')
        if [ "$key_count" -gt 0 ]; then
            print_check "pass" "Found $key_count SSH public key(s)"
        else
            print_check "warn" "No SSH public keys found"
        fi
        
        # Check ssh-agent
        if ssh-add -l >/dev/null 2>&1; then
            local loaded_keys=$(ssh-add -l | wc -l | tr -d ' ')
            print_check "pass" "ssh-agent running with $loaded_keys key(s) loaded"
        else
            print_check "warn" "ssh-agent not running or no keys loaded"
        fi
        
        # Check for ssh-keys.txt config
        if [ -f "$DOTFILES_DIR/vault-key/ssh-keys.txt" ]; then
            print_check "pass" "ssh-keys.txt configuration exists"
        else
            print_check "warn" "ssh-keys.txt not found (SSH auto-setup may not work)"
        fi
    else
        print_check "fail" "~/.ssh directory not found"
    fi
}

validate_node() {
    print_header "Node.js / NVM"
    
    # Check if NVM is installed
    export NVM_DIR="$HOME/.nvm"
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        print_check "pass" "NVM installed"
        
        # Source NVM
        . "$NVM_DIR/nvm.sh"
        
        # Check installed Node versions
        local node_versions=$(nvm list 2>/dev/null | grep -c "v" || echo "0")
        if [ "$node_versions" -gt 0 ]; then
            print_check "pass" "Node.js: $node_versions version(s) installed"
            
            # Check current version
            if command -v node >/dev/null 2>&1; then
                local current_node=$(node --version)
                print_check "pass" "Current Node version: $current_node"
            fi
        else
            print_check "warn" "No Node.js versions installed via NVM"
        fi
        
        # Check for npm
        if command -v npm >/dev/null 2>&1; then
            print_check "pass" "npm is available"
        else
            print_check "warn" "npm not found"
        fi
    else
        print_check "warn" "NVM not installed (optional)"
    fi
}

validate_python() {
    print_header "Python / pyenv"
    
    # Check if pyenv is installed
    export PYENV_ROOT="$HOME/.pyenv"
    if [ -d "$PYENV_ROOT" ]; then
        print_check "pass" "pyenv installed"
        
        # Source pyenv
        export PATH="$PYENV_ROOT/bin:$PATH"
        if command -v pyenv >/dev/null 2>&1; then
            eval "$(pyenv init -)"
            
            # Check installed Python versions
            local python_versions=$(pyenv versions 2>/dev/null | wc -l | tr -d ' ')
            if [ "$python_versions" -gt 1 ]; then
                print_check "pass" "Python: $python_versions version(s) installed"
            else
                print_check "warn" "No Python versions installed via pyenv"
            fi
            
            # Check for nvim-provider environment
            if pyenv versions 2>/dev/null | grep -q "nvim-provider"; then
                print_check "pass" "nvim-provider environment exists (for Neovim)"
                
                # Verify pynvim is installed
                if pyenv activate nvim-provider 2>/dev/null && python -c "import pynvim" 2>/dev/null; then
                    print_check "pass" "pynvim package installed in nvim-provider"
                else
                    print_check "warn" "pynvim may not be installed in nvim-provider"
                fi
            else
                print_check "warn" "nvim-provider environment not found (Neovim Python support may not work)"
            fi
        fi
    else
        print_check "warn" "pyenv not installed (optional)"
    fi
}

validate_shell() {
    print_header "Shell Configuration"
    
    # Check default shell
    local current_shell=$(echo $SHELL)
    if [[ "$current_shell" == *"zsh"* ]]; then
        print_check "pass" "Default shell is zsh: $current_shell"
    elif [[ "$current_shell" == *"bash"* ]]; then
        print_check "warn" "Default shell is bash (install.sh sets zsh)"
    else
        print_check "warn" "Default shell: $current_shell (unexpected)"
    fi
    
    # Check if DOTFILES is set
    if [ -n "$DOTFILES" ]; then
        print_check "pass" "DOTFILES environment variable set: $DOTFILES"
    else
        print_check "warn" "DOTFILES not set (may need to source shell config)"
    fi
    
    # Check HOMEBREW_PREFIX
    if [ -n "$HOMEBREW_PREFIX" ]; then
        print_check "pass" "HOMEBREW_PREFIX set: $HOMEBREW_PREFIX"
    else
        print_check "warn" "HOMEBREW_PREFIX not set (may need to source shell config)"
    fi
}

validate_vim() {
    print_header "Vim/Neovim Configuration"
    
    # Check if vim is installed
    if command -v vim >/dev/null 2>&1; then
        print_check "pass" "vim is installed"
    else
        print_check "warn" "vim not found"
    fi
    
    # Check if nvim is installed
    if command -v nvim >/dev/null 2>&1; then
        local nvim_version=$(nvim --version | head -n1)
        print_check "pass" "neovim installed: $nvim_version"
        
        # Check vim init.vim
        if [ -f "$HOME/.config/nvim/init.vim" ] || [ -f "$DOTFILES_DIR/vim/init.vim" ]; then
            print_check "pass" "Neovim init.vim exists"
        else
            print_check "warn" "Neovim init.vim not found"
        fi
    else
        print_check "warn" "neovim not installed"
    fi
}

validate_workenv() {
    print_header "Work Environment (workenv)"
    
    # Check if workenv function exists
    if type workenv >/dev/null 2>&1; then
        print_check "pass" "workenv function is available"
    else
        print_check "warn" "workenv function not found (may need to source shell config)"
    fi
    
    # Check for environment files
    if [ -d "$DOTFILES_DIR/vault-key" ]; then
        local env_count=$(find "$DOTFILES_DIR/vault-key" -name "*.env" -type f 2>/dev/null | wc -l | tr -d ' ')
        if [ "$env_count" -gt 0 ]; then
            print_check "pass" "Found $env_count environment file(s)"
        else
            print_check "warn" "No .env files found (workenv has no environments)"
        fi
    fi
}

validate_repos() {
    print_header "Repository Cloning"
    
    # Check for .repos.txt files
    if [ -d "$DOTFILES_DIR/vault-key" ]; then
        local repos_count=$(find "$DOTFILES_DIR/vault-key" -name "*.repos.txt" -type f 2>/dev/null | wc -l | tr -d ' ')
        if [ "$repos_count" -gt 0 ]; then
            print_check "pass" "Found $repos_count .repos.txt file(s)"
            
            # Check if ~/dev directory exists (common repo location)
            if [ -d "$HOME/dev" ]; then
                local cloned_repos=$(find "$HOME/dev" -maxdepth 2 -name ".git" -type d 2>/dev/null | wc -l | tr -d ' ')
                if [ "$cloned_repos" -gt 0 ]; then
                    print_check "pass" "Found $cloned_repos cloned repositories in ~/dev"
                else
                    print_check "warn" "No repositories found in ~/dev"
                fi
            else
                print_check "warn" "~/dev directory not found"
            fi
        else
            print_check "warn" "No .repos.txt files found (no repos to clone)"
        fi
    fi
}

print_summary() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Validation Summary${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}Passed: $CHECKS_PASSED${NC}"
    echo -e "${YELLOW}Warnings: $CHECKS_WARNING${NC}"
    echo -e "${RED}Failed: $CHECKS_FAILED${NC}"
    echo ""
    
    if [ $CHECKS_FAILED -eq 0 ]; then
        echo -e "${GREEN}✓ Installation validated successfully!${NC}"
        echo ""
        if [ $CHECKS_WARNING -gt 0 ]; then
            echo -e "${YELLOW}Note: Some warnings detected - these are usually optional components${NC}"
            echo ""
        fi
        echo "Next steps:"
        echo "  - Restart your terminal or run: source ~/.zshrc"
        echo "  - Run: workenv --list (to see available environments)"
        echo "  - Run: nvim (and check :checkhealth provider)"
        echo ""
        return 0
    else
        echo -e "${RED}✗ Installation validation failed - please review failed checks${NC}"
        echo ""
        echo "Common fixes:"
        echo "  - Source your shell config: source ~/.zshrc"
        echo "  - Re-run install.sh if critical components are missing"
        echo "  - Check install.sh output for error messages"
        echo ""
        return 1
    fi
}

main() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   Dotfiles Installation Validation    ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    
    validate_homebrew
    validate_vault
    validate_symlinks
    validate_ssh
    validate_node
    validate_python
    validate_shell
    validate_vim
    validate_workenv
    validate_repos
    
    print_summary
}

main "$@"