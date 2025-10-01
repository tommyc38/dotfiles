# Identified Issues in Dotfiles Repository

## Critical Issues

### 1. Shebang Syntax Error in install.sh
**File**: [`install.sh`](../install.sh:1)  
**Issue**: Line 1 contains `ls#!/bin/bash` instead of `#!/bin/bash`  
**Impact**: Script cannot execute  
**Priority**: Critical  
**Fix**: Remove "ls" prefix from shebang line

### 2. Sudo Permission Management
**Files**: [`install.sh`](../install.sh:10-13)  
**Issues**:
- Script requires sudo but runs everything as root
- Line 22: `source ~/.bash_profile` runs as root, not as user
- Font installation may fail due to permission issues
- Vault operations need user permissions, not root
- NVM/pyenv should be installed as user, not root

**Impact**: 
- User environment not properly configured
- Files created with wrong ownership
- Installation may fail or behave incorrectly

**Priority**: Critical

**Root Cause**: The script checks for root privileges at the start and requires sudo, but many operations should run as the actual user.

**Proposed Solution**:
- Split operations into two scripts:
  - `install/sudo-operations.sh` - Only truly root-required operations
  - `install/user-operations.sh` - User-level operations
- Have main `install.sh` orchestrate both with proper user context
- Use `sudo -u $SUDO_USER` for user operations when needed

### 3. Architecture Incompatibility in Multiple Scripts
**Files**: [`bin/workenv.sh`](../bin/workenv.sh:178), [`bin/repo.sh`](../bin/repo.sh:158)
**Issue**: Hardcoded `/usr/local` path won't work on Apple Silicon Macs
**Impact**: Scripts fail on Apple Silicon Macs (M1/M2/M3)
**Priority**: Critical

**Current Code** (Lines 177-185):
```bash
if [ "$(uname)" = "Darwin" ]; then
  if [ -e "/usr/local/opt/gnu-getopt/bin/getopt" ]; then
    options=$(/usr/local/opt/gnu-getopt/bin/getopt -l "$long" -o "$short" -- "$@")
```

**Problem**:
- Hardcoded `/usr/local` is Intel Mac Homebrew prefix only
- Apple Silicon Macs use `/opt/homebrew`
- Script will fail on Apple Silicon with "getopt not found"

**Fix** (using standard HOMEBREW_PREFIX pattern):
```bash
if [ "$(uname)" = "Darwin" ]; then
  # Standard HOMEBREW_PREFIX detection
  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    HOMEBREW_PREFIX="/opt/homebrew"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    HOMEBREW_PREFIX="/usr/local"
  fi
  
  if [ -e "$HOMEBREW_PREFIX/opt/gnu-getopt/bin/getopt" ]; then
    options=$("$HOMEBREW_PREFIX/opt/gnu-getopt/bin/getopt" -l "$long" -o "$short" -- "$@")
```

**Affected Scripts**:
- [`bin/workenv.sh`](../bin/workenv.sh:178) - Critical for environment switching
- [`bin/repo.sh`](../bin/repo.sh:158) - Critical for repository cloning
- [`bin/fonts.sh`](../bin/fonts.sh:566) - Already uses $(brew --prefix), compatible ✓

**Status**: Most other files already handle architecture correctly (see architecture-compatibility.md)

### 3.5 Inconsistent Variable Naming in install.sh
**File**: [`install.sh`](../install.sh:56)
**Issue**: Uses `BREW_PREFIX` instead of standard `HOMEBREW_PREFIX`
**Impact**: Inconsistent naming across codebase
**Priority**: Medium

**Current Code** (Line 56):
```bash
BREW_PREFIX="/opt/homebrew"
```

**Fix**: Rename to HOMEBREW_PREFIX for consistency:
```bash
HOMEBREW_PREFIX="/opt/homebrew"
```

**All references** (lines 62-65) also need updating:
```bash
# Before
echo "${BREW_PREFIX}/bin/bash" >> /etc/shells
# After
echo "${HOMEBREW_PREFIX}/bin/bash" >> /etc/shells
```

### 4. Commented Out Critical Operations
**File**: [`install.sh`](../install.sh:21-31)  
**Lines affected**: 21, 25, 31  
**Issue**: Critical operations are commented out:
- Line 21: Symlink creation (`sh install/symlink.sh -v -k`)
- Line 25: Homebrew package installation (`sh install/brew.sh`)
- Line 31: Python installation (`sh install/python.sh`)

**Impact**: Core functionality is disabled  
**Priority**: Critical  
**Fix**: Uncomment these lines after fixing sudo issues

### 4. Duplicate Echo Statement
**File**: [`install.sh`](../install.sh:33-34)  
**Issue**: "Decrypting Vault Files.." is printed twice  
**Impact**: Minor - cosmetic only  
**Priority**: Low  
**Fix**: Remove duplicate line

## High Priority Issues

### 5. No Error Handling
**Files**: All installation scripts  
**Issues**:
- Scripts continue even if critical operations fail
- No checking of prerequisites
- No validation of results
- Silent failures possible

**Impact**: User may think installation succeeded when it failed  
**Priority**: High  
**Proposed Solution**:
```bash
set -e  # Exit on error
set -u  # Exit on undefined variable
set -o pipefail  # Catch errors in pipes
```

### 6. Outdated Dependency URLs
**Multiple Files**:

#### NVM URL
**File**: [`install/node.sh`](../install/node.sh:11)  
**Current**: `v0.39.7`  
**Status**: Need to verify latest version  
**Priority**: High

#### VirtualBox Extension Pack
**File**: [`install/vagrant.sh`](../install/vagrant.sh:93-94)  
**Current**: `7.1.12`  
**Issue**: URLs are hardcoded, need version checking  
**Priority**: High

#### Nerd Fonts
**File**: [`bin/fonts.sh`](../bin/fonts.sh:138)
**Current**: `v3.4.0`
**Status**: Need to verify latest version
**Priority**: Medium

### 7.5. Google Fonts API Breaking Change
**File**: [`bin/fonts.sh`](../bin/fonts.sh:137)
**Issue**: Google Fonts API no longer supports zip download endpoint
**Impact**: Cannot download Google Fonts - script is completely broken for Google Fonts
**Priority**: Critical

**Current Code** (Line 137):
```bash
google_fonts_url="https://fonts.google.com/download?family="
```

**Problem**:
- The URL `https://fonts.google.com/download?family=FontName` no longer returns a zip file
- Google has deprecated this bulk download API endpoint
- Attempting to download will fail or return error pages
- This breaks all Google Fonts installation functionality

**Affected Functions**:
- Lines 298-330: `install_fonts()` Google Fonts section
- Lines 308-315: Download loop using deprecated URL

**Alternative Solutions**:

1. **Use Google Fonts GitHub Repository** (Recommended)
   - Clone: `https://github.com/google/fonts`
   - Pros: Official source, all fonts available, reliable
   - Cons: Large repository (~2GB), slower initial clone
   - Implementation: Similar to powerline fonts (git clone)

2. **Use Google Fonts API v2**
   - Requires API key from Google Cloud Console
   - Pros: Programmatic access, metadata available
   - Cons: Requires API key setup, rate limits, more complex

3. **Use Fontsource NPM Packages**
   - Individual npm packages per font
   - Pros: Version controlled, easy updates
   - Cons: Requires npm, different workflow

4. **Direct GitHub Font Files**
   - Download individual fonts from GitHub
   - Pros: No API key needed, selective downloads
   - Cons: Need to construct URLs per font

**Recommended Approach**:
Clone the google/fonts repository and copy fonts from there:
```bash
# Clone repository
git clone --depth=1 https://github.com/google/fonts.git "$google_fonts_download_dir"

# Copy OFL licensed fonts (most popular fonts)
for google_font in "${google_font_array[@]}"; do
  # Find font directory (may be in ofl/, apache/, or ufl/)
  font_dir=$(find "$google_fonts_download_dir" -type d -iname "$google_font" | head -1)
  if [ -d "$font_dir" ]; then
    find "$font_dir" -name "*.[ot]tf" -type f -exec cp {} "$font_install_dir" \;
  fi
done
```

**Priority**: Critical - This completely breaks Google Fonts functionality
**Estimated Effort**: 2-3 hours to implement and test new approach

### 7. Vault Workflow Issues
**Files**: [`bin/vault`](../bin/vault:1), [`install.sh`](../install.sh:33-46)
**Issues**:

**Critical - Vault Directory Creation**:
- Script fails if `vault-key/` directory doesn't exist
- No automatic directory creation before decryption
- User must manually create directory

**Password Security**:
- Password passed as command line argument (visible in process list)
- Password stored in environment variable
- No secure prompt option

**Missing Components**:
- No script to clone repositories from `.repos.txt` files
- No automatic symlink creation for vault files after decryption
- No permission setting for decrypted SSH keys

**Workflow Integration**:
- Vault decryption not fully integrated with install.sh
- vault-key/install.sh execution may fail if symlinks not created first
- No status messages during vault operations

**Impact**:
- Installation fails without manual intervention
- Security concerns with password handling
- Incomplete setup after vault decryption

**Priority**: High

**Proposed Solution**:
- Add directory creation to vault script
- Create `bin/clone-repos.sh` for repository management
- Set proper permissions on SSH keys (600) and config (600)
- Integrate vault workflow into main install.sh:
  1. Create vault-key directory
  2. Decrypt vault
  3. Symlink SSH keys/config
  4. Run vault-key/install.sh
  5. Clone repositories

### 8. Path Assumptions
**Files**: Multiple  
**Issues**:
- Assumes `~/.bash_profile` exists
- Assumes specific directory structures
- No checking if paths are valid

**Impact**: Script failures on different setups  
**Priority**: Medium  
**Fix**: Add existence checks before operations

### 8. Missing Repository Cloning Script
**File**: None (needs creation)
**Issue**: No script to process `.repos.txt` files and clone repositories
**Files that need it**:
- `vault-key/main.repos.txt`
- `vault-key/kofax/kofax.repos.txt`
- Any organization-specific repos.txt files

**Format of repos.txt**:
```
git@github.com:user/repo.git $HOME/target/directory
git@bitbucket.org:user/repo.git $HOME/another/directory
```

**Impact**: Manual repository cloning required
**Priority**: Medium
**Proposed**: Create `bin/clone-repos.sh` script

### 9. Workenv Script Integration
**File**: [`bin/workenv.sh`](../bin/workenv.sh:1)
**Current State**: Works well but not documented in main workflow
**Issues**:
- Not mentioned in README
- Relationship to vault workflow not explained
- Initial `.workrc` setup not automated

**Impact**: Users may not know about environment switching capability
**Priority**: Low
**Proposed**: Document in README and vault workflow docs

## Medium Priority Issues

### 10. Fonts.sh Debugging Code
**File**: [`bin/fonts.sh`](../bin/fonts.sh:309-312)  
**Issue**: Debug echo statements left in production code:
```bash
echo "Arg 1: $google_fonts_url$google_font"
echo "Arg 2 $google_fonts_download_dir/zip-files"
echo "Arg 3 $google_fonts_download_dir/$google_font"
echo "Arg 4 $google_font.zip"
```
**Impact**: Cluttered output  
**Priority**: Low  
**Fix**: Remove or make conditional on debug flag

### 11. Inconsistent PostgreSQL/Redis Handling
**File**: [`install/brew.sh`](../install/brew.sh:59-63)  
**Issues**:
- Installs specific versions (@14, @6.2)
- Auto-starts services (may not be desired)
- No option to skip or choose versions
- TODO comments indicate known issues

**Impact**: Unwanted services running, version conflicts  
**Priority**: Medium  
**Fix**: Make optional, allow version selection

### 12. No Uninstall/Cleanup Scripts
**Files**: None (missing)  
**Issue**: No way to undo installation or clean up  
**Impact**: Difficult to test or recover from issues  
**Priority**: Medium  
**Proposed**: Create uninstall and cleanup scripts

### 13. Missing Progress Indicators
**Files**: All scripts  
**Issue**: No indication of progress during long operations  
**Impact**: Poor user experience, appears frozen  
**Priority**: Medium  
**Proposed**: Add progress bars or step indicators

## Low Priority Issues

### 14. README Inconsistencies
**File**: [`README.md`](../README.md)  
**Issues**:
- Line 68: References Angular project (copy-paste error)
- Line 149: Has VirtualBox URL in Vim section
- Line 156: Has npm package installation in Webstorm section
- Incomplete sections (line 178 ends abruptly)
- Table of contents doesn't match content

**Impact**: Confusing documentation  
**Priority**: Low  
**Fix**: Complete rewrite needed

### 15. Orphaned or Unused Files
**Potential candidates** (need verification):
- `misc/brew.sh` - Duplicate of `install/brew.sh`?
- `misc/fonts.sh` - Duplicate of `bin/fonts.sh`?
- `applescripts/` - Still used?
- `ubuntu/` - Still maintained?
- `set-shells-sudo.sh` - Functionality now in `install.sh`?

**Impact**: Repository clutter  
**Priority**: Low  
**Action**: Audit and document or remove

### 16. Tmux Configuration Comments
**File**: [`install.sh`](../install.sh:70-72)  
**Issue**: Commented tmux plugin installation  
**Status**: Unclear if intentional  
**Priority**: Low  
**Action**: Document reason or uncomment

### 17. Hardcoded Font Lists
**File**: [`bin/fonts.sh`](../bin/fonts.sh:35-95)  
**Issue**: Massive hardcoded font arrays  
**Impact**: Difficult to maintain  
**Priority**: Low  
**Proposed**: Move to external configuration file

### 18. No Version Information
**Files**: All scripts  
**Issue**: No versioning or changelog  
**Impact**: Difficult to track changes  
**Priority**: Low  
**Proposed**: Add version comments and CHANGELOG.md

## Testing Gaps

### 19. No Test Suite
**Issue**: No automated testing  
**Impact**: Changes may break existing functionality  
**Priority**: High  
**Proposed**: Create test framework (see testing strategy document)

### 20. No Validation Scripts
**Issue**: No way to verify installation success  
**Impact**: Difficult to troubleshoot  
**Priority**: Medium  
**Proposed**: Create validation scripts

### 21. No Dry-Run for All Scripts
**Current Support**:
- ✅ [`bin/symlink.sh`](../bin/symlink.sh) - Has `--dry-run`
- ✅ [`bin/vault`](../bin/vault) - Has `--list`
- ❌ [`install.sh`](../install.sh) - No dry-run
- ❌ [`install/brew.sh`](../install/brew.sh) - No dry-run
- ❌ [`bin/fonts.sh`](../bin/fonts.sh) - Has `--download-only` but not full dry-run

**Priority**: High  
**Proposed**: Add `--dry-run` to all scripts

## Architecture Concerns

### 22. Monolithic install.sh
**File**: [`install.sh`](../install.sh)  
**Issue**: Single file doing too much  
**Impact**: Difficult to maintain and test  
**Priority**: Medium  
**Proposed**: Break into modular components

### 23. No Dependency Management
**Issue**: No tracking of dependencies between scripts  
**Impact**: Scripts may run in wrong order  
**Priority**: Medium  
**Proposed**: Create dependency graph and orchestration

### 24. No State Management
**Issue**: No tracking of what's installed  
**Impact**: Can't resume interrupted installation  
**Priority**: Low  
**Proposed**: Create state file tracking progress

## Security Considerations

### 25. SSH Key Permissions Not Set
**Files**: [`bin/vault`](../bin/vault:1)
**Issue**: After decryption, SSH keys and config may have wrong permissions
**Required Permissions**:
- `~/.ssh/` directory: 700
- `~/.ssh/config`: 600
- Private keys: 600
- Public keys: 644

**Impact**: SSH operations may fail or show warnings
**Priority**: Medium
**Fix**: Add permission setting after decryption

### 26. No Checksum Verification
**Files**: All download operations  
**Issue**: No verification of downloaded files  
**Impact**: Potential security risk  
**Priority**: Medium  
**Proposed**: Add checksum verification for downloads

## Summary by Priority

### Critical (Must Fix)
1. Shebang syntax error
2. Sudo permission management
3. Commented out operations

### High Priority
4. No error handling
5. Outdated dependency URLs
6. Vault password handling
7. Path assumptions
8. No test suite
9. No dry-run support

### Medium Priority
10. PostgreSQL/Redis auto-start
11. No uninstall scripts
12. Missing progress indicators
13. No validation scripts
14. Monolithic architecture

### Low Priority
15. README inconsistencies
16. Debug code in fonts.sh
17. Orphaned files
18. Hardcoded font lists
19. No versioning

## Recommended Fix Order

1. Fix critical syntax error
2. Set up testing framework
3. Fix sudo/permission issues
4. Add error handling
5. Uncomment operations
6. Update dependencies
7. Add dry-run support
8. Improve documentation
9. Address medium/low priority issues