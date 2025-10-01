# Vault Workflow Documentation

## Overview

The vault system is a comprehensive solution for managing encrypted sensitive files including SSH keys, configurations, and environment variables across multiple organizations and projects.

## Vault Structure

```
vault/                          # Encrypted files (committed to git)
└── [encrypted-files]          # Base64-encoded, AES-256-CBC encrypted

vault-key/                      # Decrypted files (gitignored)
├── config                     # SSH config file
├── workrc                     # Work environment loader
├── symlinks.txt              # Symlink definitions
├── install.sh                # Vault-specific installations
├── main                      # Main SSH private key
├── main.pub                  # Main SSH public key
├── main.env                  # Main environment variables
├── main.repos.txt           # Main repositories to clone
├── gotomconley/             # Organization-specific directory
│   ├── gotomconley          # Org SSH private key
│   ├── gotomconley.pub      # Org SSH public key
│   └── gotomconley.env      # Org environment variables
└── kofax/                    # Another organization
    ├── printix              # Org SSH private key
    ├── printix.pub          # Org SSH public key
    └── kofax.repos.txt      # Org repositories to clone
```

## Complete Vault Workflow

### 1. Decrypt Vault Files

**Command**: `vault password`

**What it does**:
1. Takes encrypted files from [`vault/`](../vault/) directory
2. Decrypts them using AES-256-CBC encryption
3. Outputs decrypted files to [`vault-key/`](../vault-key/) directory
4. **Optionally**: Saves password to `vault-key/vault_backups/.vault_password` for auto-loading

**Improvements needed**:
- Script should create [`vault-key/`](../vault-key/) directory if it doesn't exist
- Auto-load password from saved file
- Update environment variable when new password provided

**Current Usage**:
```bash
cd ~/dotfiles
vault mypassword
# or
export VAULT_PASSWORD=mypassword
vault
```

**Improved Usage** (with auto-password loading):
```bash
# First time - save password for future use
vault -o mypassword  # Saves to vault-key/vault_backups/password.txt

# Future sessions - password auto-loaded from file
vault  # Automatically uses saved password from environment

# Change password
vault -o newpassword  # Updates saved password file and environment
```

### 2. Symlink SSH Keys and Config

**File**: [`vault-key/symlinks.txt`](../vault-key/symlinks.txt:1)

**What it contains**:
```
$DOTFILES/vault-key/workrc | $HOME/.workrc
$DOTFILES/vault-key/config | $HOME/.ssh
$DOTFILES/vault-key/gotomconley/gotomconley | $HOME/.ssh
$DOTFILES/vault-key/kofax/printix | $HOME/.ssh
$DOTFILES/vault-key/main | $HOME/.ssh
```

**How it's used**:
```bash
# After decryption, symlink files
symlink.sh --file=$HOME/dotfiles/vault-key/symlinks.txt
```

**What gets symlinked**:
- **workrc** → `~/.workrc` - Work environment configuration
- **config** → `~/.ssh/config` - SSH host configurations
- **SSH keys** → `~/.ssh/` - Private keys for different services

**SSH Config Example** ([`vault-key/config`](../vault-key/config:1)):
```ssh-config
Host bitbucket.org
  user git
  AddKeysToAgent yes
  IdentityFile ~/.ssh/gotomconley

Host github.com
  user git
  AddKeysToAgent yes
  IdentityFile ~/.ssh/main
```

### 3. Install Organization-Specific Tools

**File**: [`vault-key/install.sh`](../vault-key/install.sh:1)

**What it does**:
- Installs tools specific to organizations/projects
- Can be customized per project needs

**Example content**:
```bash
#!/bin/bash

# Symlink vault files
symlink.sh --file=$HOME/dotfiles/vault-key/symlinks.txt

# Printix-specific tools
brew install haproxy

# Other org tools
brew tap heroku/brew && brew install heroku
brew install postgresql@14
brew install --cask pgadmin4
brew install redis@6.2
brew services start postgresql@14
brew services start redis@6.2
```

### 4. Clone Organization Repositories

**Tool**: [`bin/repo.sh`](../bin/repo.sh:1)

**Files**: `*.repos.txt` (e.g., [`vault-key/main.repos.txt`](../vault-key/main.repos.txt:1))

**Format**: `git_url [target_directory]`

**Example** ([`vault-key/main.repos.txt`](../vault-key/main.repos.txt:1)):
```
git@github.com:tommyc38/dotfiles.git $HOME
git@github.com:tommyc38/umbrelo.git $HOME/dev/old_projects
git@bitbucket.org:tom-conley/ng-material-plus.git $HOME/dev/gotomconley
# This is a comment
```

**Usage**:
```bash
# Clone repositories from a .repos.txt file
sh bin/repo.sh --file vault-key/main.repos.txt --default-directory $HOME/dev

# With npm install for web projects
sh bin/repo.sh --file vault-key/kofax/kofax.repos.txt --npm-install

# Dry run to see what would be cloned
sh bin/repo.sh --file vault-key/main.repos.txt --dry-run
```

**Features**:
- Reads `.repos.txt` files with git URLs and optional target directories
- Comments (lines starting with `#`) and blank lines are ignored
- `$HOME` and `~` are expanded to actual paths
- If directory not specified on line, uses `--default-directory`
- Skips cloning if repository already exists
- Optional `--npm-install` flag to install node dependencies after cloning
- Intelligent node version switching based on package-lock.json
- `--dry-run` support for testing
- Handles authentication via SSH keys from vault

### 5. Switch Organization Environments

**Tool**: [`bin/workenv.sh`](../bin/workenv.sh:1)

**Purpose**: Switch between organization-specific environment variables

**Environment Files** (e.g., `gotomconley.env`):
```bash
export NPM_REGISTRY='https://registry.npmjs.org'
export NPM_TOKEN='npm_xxxxx'
export AWS_PROFILE='gotomconley'
# ... other organization-specific variables
```

**How it works**:
1. Stores current environment in `~/.workrc`
2. Allows switching between environments
3. Unloads previous environment variables
4. Loads new environment variables

**Usage**:
```bash
# Setup in ~/.zshrc (already configured)
source ~/.workrc
workenv() {
  . workenv.sh "$@"
}

# Switch to gotomconley environment
workenv gotomconley

# Check current environment
workenv --env

# Switch to kofax environment
workenv kofax
```

**File**: [`~/.workrc`](../vault-key/workrc:1) (symlinked from vault-key)
```bash
# Loads the currently selected environment
source ~/dotfiles/vault-key/gotomconley/gotomconley.env
```

## Integration with Main Install Script

### Current State in [`install.sh`](../install.sh:33-46)

```bash
echo "Decrypting Vault Files.."
if [ -n "$VAULT_PASSWORD" ]; then
  sh bin/vault "$VAULT_PASSWORD"
else
  sh bin/vault
fi

if [ -e "$script_path/vault-key/install.sh" ]; then
  echo "Running Vault-Key Install..."
  sh vault-key/install.sh
fi
```

### Improved Workflow (Proposed)

```bash
echo "Decrypting Vault Files..."
# Ensure vault-key directory exists
mkdir -p "$DOTFILES/vault-key"

# Decrypt vault
if [ -n "$VAULT_PASSWORD" ]; then
  sh bin/vault "$VAULT_PASSWORD"
else
  sh bin/vault
fi

echo "Symlinking Vault Files..."
# Look for symlinks.txt in vault-key root
if [ -f "$DOTFILES/vault-key/symlinks.txt" ]; then
  sh bin/symlink.sh --file="$DOTFILES/vault-key/symlinks.txt" -v
fi

echo "Running Vault-Specific Installations..."
if [ -e "$DOTFILES/vault-key/install.sh" ]; then
  sh "$DOTFILES/vault-key/install.sh"
fi

echo "Cloning Repositories..."
# Find and process all .repos.txt files in vault-key
find "$DOTFILES/vault-key" -name "*.repos.txt" -type f | while read repos_file; do
  echo "Processing $repos_file..."
  sh bin/repo.sh --file "$repos_file" --default-directory "$HOME/dev"
done

echo "Setting up work environment..."
# Initial workrc will be symlinked by symlinks.txt
echo "Use 'workenv <org>' to switch between organization environments"
```

## Complete Setup Flow

### First Time Setup

1. **Clone dotfiles**
   ```bash
   cd $HOME
   git clone https://github.com/user/dotfiles.git
   cd dotfiles
   ```

2. **Run main installation** (as sudo for system operations)
   ```bash
   sudo ./install.sh myVaultPassword
   ```

3. **Installation sequence**:
   - Install Homebrew packages
   - Install Node/Python/etc.
   - **Decrypt vault** → Creates vault-key directory
   - **Symlink SSH keys** → Sets up ~/.ssh/config and keys
   - **Run vault install.sh** → Installs org-specific tools
   - **Clone repositories** → Gets all project repos
   - Setup fonts, shell, preferences

4. **Switch to organization environment**
   ```bash
   workenv gotomconley  # Switch to gotomconley environment
   cd ~/dev/gotomconley/ng-material-plus
   npm install  # Uses NPM_TOKEN from environment
   ```

### Daily Usage

**Switching Organizations**:
```bash
# Working on gotomconley projects
workenv gotomconley
cd ~/dev/gotomconley/ng-material-plus

# Switch to kofax projects
workenv kofax
cd ~/dev/kofax/some-project
```

**Benefits**:
- Automatic environment variable switching
- Correct SSH keys used per organization
- Private npm registry credentials loaded
- AWS profiles switched automatically

## Security Considerations

### What's Encrypted in Vault

✅ **Should be encrypted**:
- SSH private keys (`.`, `.pub` files)
- SSH config with host mappings
- Environment files with tokens/credentials (`.env`)
- API keys and secrets

❌ **Should NOT be encrypted**:
- Public configuration files
- Non-sensitive repository lists
- Scripts (unless they contain secrets)

### Password Management

**Current Issues**:
- Password passed as command-line argument (visible in process list)
- Password stored in environment variable

**Recommended Improvements**:
1. Use keychain/keyring for password storage
2. Prompt for password if not provided
3. Clear password from memory after use
4. Consider using SSH agent for key management

### Permission Management

**SSH Key Permissions** (Critical):
```bash
chmod 700 ~/.ssh           # Directory
chmod 600 ~/.ssh/config    # Config file
chmod 600 ~/.ssh/*         # Private keys (no extension)
chmod 644 ~/.ssh/*.pub     # Public keys
```

**Vault Script Should**:
- Set correct permissions automatically
- Verify permissions before use
- Warn if permissions are too permissive

## Missing Components

### 1. Repository Cloning Script

**File to create**: `bin/clone-repos.sh`

**Purpose**: Read `.repos.txt` files and clone repositories

**Example implementation**:
```bash
#!/bin/bash
# clone-repos.sh - Clone repositories from a repos.txt file

repos_file="$1"

if [ ! -f "$repos_file" ]; then
    echo "Repos file not found: $repos_file"
    exit 1
fi

while IFS=' ' read -r repo_url target_dir; do
    # Skip empty lines and comments
    [[ -z "$repo_url" || "$repo_url" =~ ^# ]] && continue
    
    # Expand variables
    target_dir="${target_dir/\$HOME/$HOME}"
    target_dir="${target_dir/\~/$HOME}"
    
    # Get repo name
    repo_name=$(basename "$repo_url" .git)
    full_path="$target_dir/$repo_name"
    
    # Create target directory
    mkdir -p "$target_dir"
    
    # Clone if doesn't exist
    if [ -d "$full_path" ]; then
        echo "✓ $repo_name already cloned"
    else
        echo "Cloning $repo_name..."
        git clone "$repo_url" "$full_path"
    fi
done < "$repos_file"
```

### 2. Vault Directory Creation

**Fix needed in**: [`bin/vault`](../bin/vault:1)

**Current issue**: Script fails if `vault-key/` doesn't exist

**Fix**:
```bash
# In encrypt_decrypt_files function, before operations:
if [ "$operation" == "decrypt" ] && [ ! -d "$target_directory" ]; then
    mkdir -p "$target_directory"
fi
```

### 3. Workrc Initialization

**File to create**: `vault-key/workrc` (template)

**Purpose**: Initial work environment configuration

**Example**:
```bash
# ~/.workrc - Current work environment
# This file is managed by workenv.sh
# To switch environments, use: workenv <environment-name>

# Default environment (customize after first setup)
source $HOME/dotfiles/vault-key/main.env
```

## Testing the Vault Workflow

### Test Vault Encryption/Decryption

```bash
# Create test vault directory
mkdir -p test/fixtures/test-vault
echo "test secret" > test/fixtures/test-vault/secret.txt

# Encrypt
echo "testpass" | vault --encrypt

# Decrypt
echo "testpass" | vault

# Verify
cat vault-key/secret.txt
```

### Test Symlink Operations

```bash
# Test with mock environment
TEST_MODE=1 symlink.sh --file=vault-key/symlinks.txt --dry-run
```

### Test Repository Cloning

```bash
# Test with dry-run
DRY_RUN=1 clone-repos.sh vault-key/main.repos.txt
```

### Test Environment Switching

```bash
# Test workenv
workenv --env
workenv gotomconley
workenv --env
```

## Summary

The vault workflow provides:

✅ **Encrypted Storage**: Secure storage of SSH keys and credentials
✅ **Organization Management**: Easy switching between different organizations
✅ **Automated Setup**: Complete environment setup from encrypted vault
✅ **Repository Management**: Automatic cloning of organization repositories
✅ **Environment Variables**: Organization-specific environment configuration
✅ **SSH Key Management**: Automatic SSH key and config setup

The workflow enables working across multiple organizations with different:
- SSH keys for different git hosts
- NPM registries and tokens
- AWS profiles
- Environment configurations
- Project repositories