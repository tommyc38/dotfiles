# Dotfiles Repository Implementation Plan

## Overview

This plan addresses the cleanup and modernization of the dotfiles repository to ensure reliable Mac development environment setup. The repository will be reorganized to handle sudo/non-sudo operations correctly, include a robust testing framework, and maintain up-to-date dependencies.

## Current Issues Identified

### Critical Issues

1. **Sudo Permission Management**
   - [`install.sh`](../install.sh:10) requires sudo but many operations shouldn't run as root
   - Sourcing bash_profile as root doesn't affect the user's environment
   - Font installation and vault operations have permission issues
   - Need to separate root-required from user-level operations

2. **Script Errors**
   - Line 1 of [`install.sh`](../install.sh:1) has "ls#!/bin/bash" (typo)
   - Commented-out critical operations (symlink, brew, python)
   - No clear execution flow or error handling

3. **Testing Limitations**
   - No way to test scripts without affecting the system
   - No dry-run capabilities
   - Cannot validate changes before applying

### High Priority Issues

4. **Outdated Dependencies**
   - NVM URL in [`install/brew.sh`](../install/brew.sh:1) needs version check
   - VirtualBox extension pack URLs in [`install/vagrant.sh`](../install/vagrant.sh:93-94) need updating
   - Nerd Fonts URL in [`bin/fonts.sh`](../bin/fonts.sh:138) may be outdated
   - Python versions in [`install/python.sh`](../install/python.sh:5-7) should be reviewed

5. **Documentation Gaps**
   - [`README.md`](../README.md:1) incomplete and contains incorrect information
   - No clear setup workflow documented
   - Testing procedures not explained
   - Post-installation steps unclear

## Implementation Phases

### Phase 1: Core Script Fixes and Reorganization

**Goal**: Fix critical issues and separate sudo/non-sudo operations

#### 1.1 Fix install.sh Shebang and Structure
- [ ] Fix the "ls#!/bin/bash" typo on line 1
- [ ] Uncomment all critical operations
- [ ] Add comprehensive error handling
- [ ] Add progress indicators

#### 1.1.5 Fix Architecture Compatibility Issues
- [ ] **Critical**: Fix [`bin/workenv.sh`](../bin/workenv.sh:178):
  - Replace hardcoded `/usr/local` with standard HOMEBREW_PREFIX detection
  - Use consistent variable name: `HOMEBREW_PREFIX` (not BREW_PREFIX)
  - Test on both Intel and Apple Silicon Macs
- [ ] Fix naming in [`install.sh`](../install.sh:56):
  - Rename `BREW_PREFIX` to `HOMEBREW_PREFIX` for consistency
- [ ] **Optional consistency updates**:
  - Update bin/vault to use HOMEBREW_PREFIX pattern
  - Update bin/fonts.sh to use HOMEBREW_PREFIX pattern
- [ ] Audit all other bin/ scripts for hardcoded paths
- [ ] Verify all scripts use consistent `HOMEBREW_PREFIX` variable name
- [ ] Document architecture requirements in README

#### 1.2 Separate Sudo and Non-Sudo Operations
- [ ] Create [`install/sudo-operations.sh`](../install/sudo-operations.sh) for operations requiring root:
  - System package installations via Homebrew (some casks)
  - Shell additions to `/etc/shells`
  - User shell changes via `chsh`
- [ ] Create [`install/user-operations.sh`](../install/user-operations.sh) for user-level operations:
  - Symlink creation (via [`bin/symlink.sh`](../bin/symlink.sh))
  - Vault decryption (via [`bin/vault`](../bin/vault))
  - Font installation (via [`bin/fonts.sh`](../bin/fonts.sh))
  - NVM/Node installation
  - Python/pyenv installation
  - OSX preferences
- [ ] Refactor [`install.sh`](../install.sh) to orchestrate both scripts:
  - Run sudo operations first
  - Then run user operations (as actual user, not root)
  - Properly handle `$SUDO_USER` throughout

#### 1.3 Improve Individual Scripts
- [ ] [`install/brew.sh`](../install/brew.sh):
  - Add version checking for packages
  - Add skip-if-installed logic
  - Add error handling for failed installations
  - Make PostgreSQL/Redis service starts optional
- [ ] [`install/node.sh`](../install/node.sh):
  - Already well-structured, minor improvements only
  - Add verification steps
- [ ] [`install/python.sh`](../install/python.sh):
  - Already well-structured, verify version list is current
  - Add verification steps
- [ ] [`install/osx.sh`](../install/osx.sh):
  - Review and update settings for modern macOS
  - Add comments for each setting
- [ ] [`install/vagrant.sh`](../install/vagrant.sh):
  - Update VirtualBox extension pack URLs
  - Add version detection
  - Add error handling

#### 1.4 Fix Vault Workflow Issues
- [ ] [`bin/vault`](../bin/vault:1):
  - **Critical**: Create `vault-key/` directory if it doesn't exist
  - Set proper permissions on decrypted SSH keys (600)
  - Set proper permissions on SSH config (600)
  - Set proper permissions on password file (600)
  - Add validation of decrypted files
  - **Improve password handling**:
    - Check for VAULT_PASSWORD environment variable first
    - Update environment variable when new password provided
    - Set password file permissions to 600
- [ ] Update [`bash/bashrc.symlink`](../bash/bashrc.symlink:1):
  - Add auto-load of vault password from file
  - Check for `vault-key/vault_backups/password.txt`
  - Export to VAULT_PASSWORD if file exists
- [ ] Update [`zsh/zshrc.symlink`](../zsh/zshrc.symlink:1):
  - Add auto-load of vault password from file
  - Same logic as bashrc
- [ ] Fix [`bin/repo.sh`](../bin/repo.sh:158) architecture compatibility:
  - Hardcoded `/usr/local` path (same issue as workenv.sh)
  - Replace with HOMEBREW_PREFIX detection for gnu-getopt
- [ ] Update [`install.sh`](../install.sh:33-46) vault workflow section:
  - Ensure vault-key directory creation before decryption
  - **After decryption, check for vault-key/symlinks.txt**:
    - If found, process with: `sh bin/symlink.sh -f vault-key/symlinks.txt -v`
  - Run vault-key/install.sh if present (existing behavior)
  - **Find and process all *.repos.txt files in vault-key**:
    - Use `find vault-key -name "*.repos.txt" -type f`
    - For each file: `sh bin/repo.sh --file "$repos_file" --default-directory "$HOME/dev"`
  - Add status messages for each step

#### 1.5 Fix Google Fonts API Breaking Change
- [ ] **Critical**: [`bin/fonts.sh`](../bin/fonts.sh:137-315):
 - **Problem**: Google Fonts API no longer supports `https://fonts.google.com/download?family=` endpoint
 - **Impact**: All Google Fonts downloads are completely broken
 - **Solution**: Switch to Google Fonts GitHub repository approach
 - **Implementation**:
   - Change download method from individual zip downloads to git clone
   - Clone `https://github.com/google/fonts` repository (use `--depth=1` for shallow clone)
   - Search for fonts in `ofl/`, `apache/`, and `ufl/` directories
   - Copy font files from repository to installation directory
   - Update download function to handle git repository instead of zip files
   - Update installation logic to find fonts in cloned repository
 - **Code Changes Required**:
   ```bash
   # Replace lines 137 with new approach:
   google_fonts_repo="https://github.com/google/fonts"
   
   # Update download function (lines 162-200) to:
   function download_google_fonts() {
     if [ ! -d "$google_fonts_download_dir/.git" ]; then
       git clone --depth=1 "$google_fonts_repo" "$google_fonts_download_dir"
     fi
   }
   
   # Update install function (lines 298-330) to search repository:
   for google_font in "${google_font_array[@]}"; do
     # Search in all license directories
     font_dir=$(find "$google_fonts_download_dir" -type d -iname "$google_font" | head -1)
     if [ -d "$font_dir" ]; then
       find "$font_dir" -name "*.[ot]tf" -type f -exec cp {} "$font_install_dir" \;
     fi
   done
   ```
 - **Testing**: Verify fonts can be found and installed from repository structure
 - **Priority**: Critical - Must be fixed before any Google Fonts installation will work
 - **Estimated Effort**: 2-3 hours

### Phase 2: Testing Framework

**Goal**: Create comprehensive testing without VMs or Docker

#### 2.1 Create Test Directory Structure
- [ ] Create [`test/`](../test/) directory with subdirectories:
  - `test/mock-home/` - Mock home directory for testing
  - `test/mock-system/` - Mock system directories
  - `test/results/` - Test output and logs
  - `test/fixtures/` - Sample configuration files

#### 2.2 Create Testing Scripts
- [ ] Create [`test/test-framework.sh`](../test/test-framework.sh):
  - Test harness for running all tests
  - Environment setup/teardown
  - Results reporting
- [ ] Create [`test/test-symlinks.sh`](../test/test-symlinks.sh):
  - Test symlink creation without affecting real system
  - Test backup functionality
  - Test restore functionality
- [ ] Create [`test/test-install.sh`](../test/test-install.sh):
  - Dry-run installation checks
  - Dependency verification
  - Script syntax validation
- [ ] Create [`test/test-vault.sh`](../test/test-vault.sh):
  - Test encryption/decryption
  - Test password handling
  - Test backup functionality

#### 2.3 Add Dry-Run Capabilities
- [ ] Add `--dry-run` flag to all major scripts:
  - [`install.sh`](../install.sh) - overall orchestration
  - [`bin/symlink.sh`](../bin/symlink.sh) - already has this ✓
  - [`bin/fonts.sh`](../bin/fonts.sh) - add dry-run support
  - [`bin/vault`](../bin/vault) - enhance dry-run
- [ ] Add `--test-mode` flag that uses test directories instead of real paths

#### 2.4 Create Test Documentation
- [ ] Create [`test/README.md`](../test/README.md):
  - Explain testing approach
  - How to run tests
  - How to interpret results
  - How to add new tests

### Phase 3: Update Dependencies and URLs

**Goal**: Ensure all external dependencies are current and properly managed

#### 3.1 Audit and Update URLs
- [ ] Check and update NVM installation URL in [`install/brew.sh`](../install/brew.sh)
- [ ] Update VirtualBox extension pack URLs in [`install/vagrant.sh`](../install/vagrant.sh:93-94)
- [ ] Verify Nerd Fonts URL in [`bin/fonts.sh`](../bin/fonts.sh:138)
- [ ] Check Powerline Fonts URL in [`bin/fonts.sh`](../bin/fonts.sh:139)
- [ ] Verify Google Fonts URL in [`bin/fonts.sh`](../bin/fonts.sh:137)

#### 3.2 Create Dependency Management
- [ ] Create [`config/dependencies.conf`](../config/dependencies.conf):
  - Centralized version management
  - URL templates
  - Version checking scripts
- [ ] Create [`bin/check-updates.sh`](../bin/check-updates.sh):
  - Check for outdated URLs
  - Verify package availability
  - Report recommended updates

#### 3.3 Add Version Pinning
- [ ] Document current working versions
- [ ] Add optional version pinning in installation scripts
- [ ] Create migration guide for version updates

### Phase 4: Documentation Improvements

**Goal**: Complete, accurate, and helpful documentation

#### 4.1 Update Main README
- [ ] Fix incorrect information in current [`README.md`](../README.md)
- [ ] Document new sudo/non-sudo separation
- [ ] Add clear installation workflow section
- [ ] Update prerequisites section
- [ ] Add troubleshooting section
- [ ] Document testing procedures
- [ ] Add examples for common scenarios

#### 4.2 Create Supplementary Documentation
- [ ] Create [`docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md):
  - Repository structure explanation
  - Script relationships and dependencies
  - Design decisions and rationale
- [ ] Create [`docs/TROUBLESHOOTING.md`](../docs/TROUBLESHOOTING.md):
  - Common issues and solutions
  - Permission problems
  - Installation failures
- [ ] Create [`docs/DEVELOPMENT.md`](../docs/DEVELOPMENT.md):
  - How to modify scripts
  - Testing new changes
  - Contributing guidelines

#### 4.3 Inline Documentation
- [ ] Add comprehensive comments to all scripts
- [ ] Document each function's purpose and parameters
- [ ] Add usage examples in comments
- [ ] Document any non-obvious logic

### Phase 5: Additional Improvements

**Goal**: Polish and optional enhancements

#### 5.1 Script Enhancements
- [ ] Add logging throughout installation process
- [ ] Create installation report/summary
- [ ] Add rollback capability
- [ ] Add idempotency checks (safe to run multiple times)

#### 5.2 User Experience
- [ ] Add interactive mode with prompts
- [ ] Add progress bars for long operations
- [ ] Create quick-start mode with sensible defaults
- [ ] Add uninstall/cleanup scripts

#### 5.3 CI/CD Considerations
- [ ] Add shell linting (shellcheck)
- [ ] Add automated testing
- [ ] Add pre-commit hooks
- [ ] Consider GitHub Actions for testing

## Success Criteria

### Must Have
- ✅ All scripts run without errors on a fresh Mac
- ✅ Sudo operations properly separated from user operations
- ✅ Testing framework allows validation without system modification
- ✅ All URLs and dependencies are current
- ✅ README provides clear installation instructions
- ✅ Scripts are idempotent (safe to run multiple times)

### Should Have
- ✅ Comprehensive test coverage
- ✅ Detailed troubleshooting documentation
- ✅ Rollback capabilities
- ✅ Clear logging and error messages
- ✅ Installation progress indicators

### Nice to Have
- ✅ Interactive installation mode
- ✅ Automated dependency checking
- ✅ CI/CD pipeline
- ✅ Uninstall scripts

## Risk Mitigation

### Backup Strategy
- Create system backup before running installation
- Test all changes in test mode first
- Maintain backup directory for symlink operations
- Document rollback procedures

### Permission Issues
- Clearly document which operations need sudo
- Warn users about permission requirements
- Provide alternative approaches when possible
- Test with non-admin users where applicable

### Compatibility
- Test on multiple macOS versions
- Document minimum OS requirements
- Handle architecture differences (Intel vs Apple Silicon)
- Provide fallbacks for failed operations

## Timeline Estimate

- **Phase 1**: 2-3 days (Core fixes and reorganization)
- **Phase 2**: 2-3 days (Testing framework)
- **Phase 3**: 1 day (Dependency updates)
- **Phase 4**: 1-2 days (Documentation)
- **Phase 5**: 1-2 days (Additional improvements)

**Total Estimated Time**: 7-11 days

## Next Steps

1. Review and approve this implementation plan
2. Begin Phase 1 with script fixes
3. Set up testing framework before making major changes
4. Test each phase thoroughly before proceeding
5. Update documentation as changes are made

---

**Note**: This plan can be adjusted based on priorities and time constraints. The most critical items are in Phase 1 (core fixes) and Phase 2 (testing framework).