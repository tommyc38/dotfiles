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
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
    elif [ "$status" = "fail" ]; then
        echo -e "${RED}✗${NC} $message"
        CHECKS_FAILED=$((CHECKS_FAILED + 1))
    elif [ "$status" = "warn" ]; then
        echo -e "${YELLOW}⚠${NC} $message"
        CHECKS_WARNING=$((CHECKS_WARNING + 1))
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
        
        # Everything in the Brewfile installed?
        local missing
        missing="$(brew bundle check --file "$DOTFILES_DIR/Brewfile" --verbose 2>/dev/null | grep '^→' | sed 's/^→ //')"
        if [ -z "$missing" ]; then
            print_check "pass" "Everything in the Brewfile is installed"
        else
            print_check "warn" "Brewfile entries missing/outdated ($(echo "$missing" | wc -l | tr -d ' ')) — run: brew bundle --file $DOTFILES_DIR/Brewfile"
            echo "$missing" | sed 's/^/    /' | head -10
        fi
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
            print_check "pass" "Vault password file exists (vault-key/password.txt)"

            # vault-key/ edited but never re-encrypted? (anything newer than the newest vault/ file)
            local newest_vault newer
            newest_vault="$(find "$DOTFILES_DIR/vault" -type f -not -name .DS_Store -print0 2>/dev/null | xargs -0 ls -t 2>/dev/null | head -1)"
            if [ -n "$newest_vault" ]; then
                newer="$(find "$DOTFILES_DIR/vault-key" -path '*/vault_backups' -prune -o -type f -not -name .DS_Store -newer "$newest_vault" -print 2>/dev/null | head -5)"
                if [ -z "$newer" ]; then
                    print_check "pass" "vault/ is up to date with vault-key/"
                else
                    print_check "warn" "vault-key/ has changes not encrypted into vault/ — run: vault -e"
                    echo "$newer" | sed "s#$DOTFILES_DIR/#    #"
                fi
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
        "$HOME/.bash_profile"
        "$HOME/.ideavimrc"
        "$HOME/.vimrc"
        "$HOME/.config/karabiner"
        "$HOME/Library/Application Support/Code/User/settings.json"
        "$HOME/.npmrc"
        "$HOME/.ssh/config"
        "$HOME/.certs/tungsten-ca-chain.pem"
    )
    
    for link in "${symlinks[@]}"; do
        local name="${link/#$HOME/~}"
        if [ -L "$link" ] && [ -e "$link" ]; then
            print_check "pass" "$name → $(readlink "$link")"
        elif [ -L "$link" ]; then
            print_check "fail" "$name is a broken symlink → $(readlink "$link")"
        elif [ -e "$link" ]; then
            print_check "warn" "$name exists but is not a symlink (run: bin/symlink.sh, see README)"
        else
            print_check "fail" "$name not found"
        fi
    done
    
    # ~/.gitconfig is a local file that includes the shared one (not a symlink).
    if git config --global --get-all include.path 2>/dev/null | grep -qxF "$DOTFILES_DIR/git/gitconfig"; then
        print_check "pass" "~/.gitconfig includes git/gitconfig"
    else
        print_check "fail" "~/.gitconfig doesn't include git/gitconfig (run: ./install.sh --only symlinks)"
    fi

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
        local ssh_perms=$(/usr/bin/stat -f "%Lp" "$HOME/.ssh" 2>/dev/null)  # BSD stat; GNU stat may be first on PATH
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
        local node_versions=$(ls -d "$NVM_DIR"/versions/node/v* 2>/dev/null | wc -l | tr -d ' ')
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
    
    # This script runs in bash, so ask a real interactive zsh what it ends up with.
    local zsh_prefix
    zsh_prefix="$(zsh -i -c 'echo $HOMEBREW_PREFIX' 2>/dev/null </dev/null | tail -1)"
    if [ -n "$zsh_prefix" ]; then
        print_check "pass" "zsh sets HOMEBREW_PREFIX: $zsh_prefix"
    else
        print_check "warn" "zsh doesn't set HOMEBREW_PREFIX (is ~/.zshrc linked?)"
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
    if zsh -i -c 'whence -w workenv' 2>/dev/null </dev/null | grep -q function; then
        print_check "pass" "workenv function is available"
    else
        print_check "warn" "workenv function not found (may need to source shell config)"
    fi
    
    # Check for environment files
    if [ -d "$DOTFILES_DIR/vault-key" ]; then
        local env_count=$(find "$DOTFILES_DIR/vault-key" -path '*/vault_backups' -prune -o -name "*.env" -type f -print 2>/dev/null | wc -l | tr -d ' ')
        if [ "$env_count" -gt 0 ]; then
            print_check "pass" "Found $env_count environment file(s)"
        else
            print_check "warn" "No .env files found (workenv has no environments)"
        fi
    fi
}

validate_auth() {
    print_header "Code Hosts & Work Tools (bin/dev-auth.sh --check)"

    local line
    while IFS= read -r line; do
        case "$line" in
            *✓*) print_check "pass" "${line#*✓ }" ;;
            *✗*) print_check "fail" "${line#*✗ }" ;;
            *"! "*) print_check "warn" "${line#*! }" ;;
        esac
    done < <(NO_COLOR=1 bash "$SCRIPT_DIR/dev-auth.sh" --check 2>&1 </dev/null | cat)
}

validate_workenv_dirs() {
    print_header "Folder-based work environments (vault-key/workenv-dirs.txt)"
    local map="$DOTFILES_DIR/vault-key/workenv-dirs.txt" dir name expanded
    if [ ! -f "$map" ]; then
        print_check "warn" "No folder mapping; every shell uses the ~/.workrc default"
        return
    fi
    while read -r dir name || [ -n "$dir" ]; do
        case "$dir" in ""|\#*) continue ;; esac
        expanded="${dir/#\$HOME/$HOME}"; expanded="${expanded/#\~/$HOME}"
        if [ -z "$(find "$DOTFILES_DIR/vault-key" -maxdepth 3 -path '*/vault_backups' -prune -o -type f -name "$name.env" -print 2>/dev/null | head -1)" ]; then
            print_check "fail" "$dir → $name: no vault-key/**/$name.env"
        elif [ ! -d "$expanded" ]; then
            print_check "warn" "$dir → $name: folder doesn't exist (yet)"
        else
            print_check "pass" "$dir → $name"
        fi
    done < "$map"
}

validate_claude() {
    print_header "Claude Code"
    local claude_bin
    claude_bin="$(command -v claude || echo "$HOME/.local/bin/claude")"
    if [ -x "$claude_bin" ]; then
        print_check "pass" "Claude Code $("$claude_bin" --version 2>/dev/null | cut -d' ' -f1)"
    else
        print_check "fail" "Claude Code not installed (run: ./install.sh --only claude)"
        return
    fi
    if [ -L "$HOME/.claude/settings.json" ] && [ "$(readlink "$HOME/.claude/settings.json")" = "$DOTFILES_DIR/vault-key/claude/settings.json" ]; then
        print_check "pass" "~/.claude/settings.json → vault-key/claude/settings.json"
    else
        print_check "warn" "~/.claude/settings.json isn't linked from the vault (run: ./install.sh --only symlinks)"
    fi
    if jq -e '.plugins["nx@nx-claude-plugins"][]? | select(.scope == "user")' "$HOME/.claude/plugins/installed_plugins.json" >/dev/null 2>&1; then
        print_check "pass" "Plugin nx@nx-claude-plugins (user)"
    else
        print_check "warn" "Plugin nx@nx-claude-plugins not installed at user scope (run: ./install.sh --only claude)"
    fi
    local mcp
    for mcp in atlassian playwright context7; do
        if jq -e --arg n "$mcp" '.mcpServers[$n]' "$HOME/.claude.json" >/dev/null 2>&1; then
            print_check "pass" "MCP server $mcp (user) — health: claude mcp list"
        else
            print_check "warn" "MCP server $mcp missing (run: ./install.sh --only claude)"
        fi
    done
}

validate_repos() {
    print_header "Repository Cloning"
    
    # Check for .repos.txt files
    if [ -d "$DOTFILES_DIR/vault-key" ]; then
        local repos_count=$(find "$DOTFILES_DIR/vault-key" -path '*/vault_backups' -prune -o -name "*.repos.txt" -type f -print 2>/dev/null | wc -l | tr -d ' ')
        if [ "$repos_count" -gt 0 ]; then
            print_check "pass" "Found $repos_count .repos.txt file(s)"
            
            # Check if ~/dev directory exists (common repo location)
            if [ -d "$HOME/dev" ]; then
                local cloned_repos=$(find "$HOME/dev" -maxdepth 3 -name ".git" -type d 2>/dev/null | wc -l | tr -d ' ')
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
    validate_workenv_dirs
    validate_repos
    validate_claude
    validate_auth
    
    print_summary
}

main "$@"