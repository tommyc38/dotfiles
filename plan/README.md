# Dotfiles Repository Implementation Plan

**Status**: Planning Complete, Ready for Implementation  
**Last Updated**: 2025-10-01

## Quick Navigation

- 📋 [**Implementation Plan**](implementation-plan.md) - Detailed phase-by-phase implementation guide
- 🐛 [**Issues Identified**](issues-identified.md) - Comprehensive list of all identified issues
- 🧪 [**Testing Strategy**](testing-strategy.md) - Testing approach without VMs/Docker
- 🔐 [**Vault Workflow**](vault-workflow.md) - Complete vault encryption/decryption and organization management
- 🖥️ [**Architecture Compatibility**](architecture-compatibility.md) - Intel vs Apple Silicon Mac compatibility
- 📁 [**Directory Structure**](directory-structure.md) - Structure analysis and reorganization recommendations

## Executive Summary

This implementation plan addresses the modernization and cleanup of the dotfiles repository to ensure reliable Mac development environment setup. The plan is organized into 5 phases over an estimated 7-11 days.

### Critical Issues to Address

1. **Shebang syntax error** in [`install.sh`](../install.sh:1) preventing execution
2. **Architecture incompatibility** in [`bin/workenv.sh`](../bin/workenv.sh:178) - hardcoded Intel path
3. **Sudo permission management** causing files to be created with wrong ownership
4. **Commented-out operations** disabling core functionality
5. **Vault directory creation** - script fails without manual intervention
6. **No testing framework** making validation dangerous
7. **Outdated dependencies** requiring URL updates

### Key Improvements

✅ Separate sudo and non-sudo operations
✅ Fix vault workflow (directory creation, permissions, repository cloning)
✅ Create comprehensive testing framework
✅ Update all dependency URLs
✅ Add error handling and logging
✅ Improve documentation (including vault workflow)
✅ Enable safe testing without system modification

## Implementation Phases

### Phase 1: Core Script Fixes (3-4 days)
**Priority**: Critical

- Fix syntax errors
- Separate sudo/non-sudo operations
- Uncomment critical operations
- Add error handling

**Status**: 🔴 Not Started

### Phase 2: Testing Framework (2-3 days)
**Priority**: Critical

- Create test directory structure
- Implement mock environments
- Add dry-run capabilities
- Create test documentation

**Status**: 🔴 Not Started

### Phase 3: Dependency Updates (1 day)
**Priority**: High

- Update NVM URL
- Update VirtualBox URLs
- Verify font URLs
- Create update checking script

**Status**: 🔴 Not Started

### Phase 4: Documentation (1-2 days)
**Priority**: High

- Rewrite README
- Create architecture docs
- Add troubleshooting guide
- Improve inline comments

**Status**: 🔴 Not Started

### Phase 5: Polish & Enhancements (1-2 days)
**Priority**: Medium

- Add progress indicators
- Create validation scripts
- Add rollback capabilities
- Improve user experience

**Status**: 🔴 Not Started

## Quick Start for Implementation

### Prerequisites

Before starting implementation:
1. ✅ Read all planning documents
2. ✅ Create backup of current repository
3. ✅ Set up development branch
4. ✅ Review and approve plan

### Step-by-Step Guide

```bash
# 1. Create feature branch
git checkout -b refactor/dotfiles-modernization

# 2. Start with Phase 1
# Fix critical issues in install.sh
# - Fix shebang on line 1
# - Create sudo-operations.sh
# - Create user-operations.sh
# - Refactor install.sh

# 3. Set up testing (Phase 2)
mkdir -p test/{unit,integration,fixtures,mock-environment,results}
# Create test-framework.sh
# Create initial test files

# 4. Test changes
./test/test-framework.sh

# 5. Continue through remaining phases
# Following implementation-plan.md

# 6. Final validation
./test/validate-installation.sh
```

## Current File Structure

```
dotfiles/
├── install.sh                 # Main installation script (needs major refactor)
├── bin/
│   ├── fonts.sh              # Font installation (works, needs minor fixes)
│   ├── symlink.sh            # Symlink manager (works well)
│   └── vault                 # Vault encryption (works, needs security improvements)
├── install/
│   ├── brew.sh               # Homebrew packages (needs updates)
│   ├── node.sh               # Node/NVM (works well)
│   ├── osx.sh                # macOS settings (works)
│   ├── python.sh             # Python/pyenv (works well)
│   └── vagrant.sh            # Vagrant/VirtualBox (needs URL updates)
├── bash/                     # Bash configuration files
├── zsh/                      # ZSH configuration files
├── vim/                      # Vim configuration
└── plan/                     # This implementation plan ✨
    ├── README.md            # This file
    ├── implementation-plan.md
    ├── issues-identified.md
    └── testing-strategy.md
```

## Main Scripts Overview

### Currently Used Scripts

These are the scripts you identified as actively used:

| Script | Status | Issues | Priority |
|--------|--------|--------|----------|
| [`install.sh`](../install.sh) | 🔴 Broken | Syntax error, sudo issues, commented code | Critical |
| [`bin/fonts.sh`](../bin/fonts.sh) | 🟡 Works | Debug code, needs dry-run | Low |
| [`bin/symlink.sh`](../bin/symlink.sh) | 🟢 Good | Minor improvements only | Low |
| [`bin/vault`](../bin/vault) | 🟡 Works | Security concerns | Medium |
| [`install/brew.sh`](../install/brew.sh) | 🟡 Works | Outdated URLs, auto-start services | High |
| [`install/node.sh`](../install/node.sh) | 🟢 Good | Minor improvements only | Low |
| [`install/osx.sh`](../install/osx.sh) | 🟢 Good | Review settings for modern macOS | Low |
| [`install/python.sh`](../install/python.sh) | 🟢 Good | Verify version list | Low |
| [`install/vagrant.sh`](../install/vagrant.sh) | 🟡 Works | Outdated URLs | High |

### Scripts to Audit

These scripts exist but their usage is unclear:

- `misc/brew.sh` - Possible duplicate?
- `misc/fonts.sh` - Possible duplicate?
- `set-shells-sudo.sh` - Functionality in install.sh?
- `applescripts/*` - Still used?
- `ubuntu/*` - Still maintained?

## Testing Approach

### Without VMs or Docker

Our testing strategy uses:

1. **Dry-Run Mode**: Scripts log actions without executing
2. **Mock Environments**: Test directories instead of real system
3. **Function Interception**: Mock system commands
4. **Validation Scripts**: Verify without modifying

### Test Execution

```bash
# Run all tests
./test/test-framework.sh

# Run specific suite
./test/unit/test-symlinks.sh

# Run with integration tests
RUN_INTEGRATION=1 ./test/test-framework.sh

# Dry-run actual installation
DRY_RUN=1 ./install.sh
```

## Success Criteria

### Must Have (Blocking Release)
- [ ] All scripts execute without errors
- [ ] Sudo operations properly separated
- [ ] Testing framework functional
- [ ] All URLs current and working
- [ ] README provides clear instructions
- [ ] Scripts are idempotent

### Should Have (Important)
- [ ] Comprehensive test coverage
- [ ] Troubleshooting documentation
- [ ] Error messages are clear
- [ ] Progress indicators
- [ ] Validation scripts

### Nice to Have (Optional)
- [ ] Interactive installation mode
- [ ] Automated dependency checking
- [ ] CI/CD pipeline
- [ ] Uninstall scripts

## Timeline

| Phase | Duration | Dependencies |
|-------|----------|--------------|
| Phase 1: Core Fixes | 2-3 days | None |
| Phase 2: Testing | 2-3 days | Phase 1 |
| Phase 3: Dependencies | 1 day | Phase 1 |
| Phase 4: Documentation | 1-2 days | Phase 1-3 |
| Phase 5: Polish | 1-2 days | Phase 1-4 |

**Total Estimated**: 7-11 days

## Risk Mitigation

### Before Making Changes

1. ✅ **Backup**: Create full system backup
2. ✅ **Branch**: Work on feature branch
3. ✅ **Test**: Use test framework extensively
4. ✅ **Document**: Keep detailed notes

### During Implementation

1. ✅ **Small Changes**: Make incremental changes
2. ✅ **Test Often**: Run tests after each change
3. ✅ **Commit Often**: Frequent commits with clear messages
4. ✅ **Review**: Have changes reviewed

### Recovery Plan

If something goes wrong:

```bash
# Restore from backup
./bin/symlink.sh --restore

# Roll back to previous version
git checkout main
git reset --hard HEAD~1

# Remove partially installed items
# (Uninstall scripts to be created)
```

## Next Steps

1. **Review Plan**: Ensure all stakeholders approve
2. **Ask Questions**: Clarify any unclear items
3. **Begin Phase 1**: Start with critical fixes
4. **Iterate**: Adjust plan as needed

## Questions to Resolve

Before implementation, clarify:

- [ ] Which files in `misc/` and `applescripts/` should be kept?
- [ ] Is Ubuntu support still needed?
- [ ] What macOS versions should be supported?
- [ ] Should PostgreSQL/Redis auto-start be configurable?
- [ ] Preference for interactive vs. non-interactive install?

## Resources

### Documentation Files
- [Implementation Plan](implementation-plan.md) - Detailed tasks and phases
- [Issues Identified](issues-identified.md) - Complete issue list
- [Testing Strategy](testing-strategy.md) - Testing methodology

### External References
- [Homebrew Documentation](https://docs.brew.sh)
- [NVM Releases](https://github.com/nvm-sh/nvm/releases)
- [VirtualBox Downloads](https://www.virtualbox.org/wiki/Downloads)
- [Nerd Fonts Releases](https://github.com/ryanoasis/nerd-fonts/releases)

### Key Features

**Vault System**:
- Encrypted storage for SSH keys, configs, and credentials
- Organization-specific environment management
- Automatic repository cloning
- Work environment switching via `workenv` command

See [Vault Workflow Documentation](vault-workflow.md) for complete details.

## Contact & Support

For questions or issues during implementation:
1. Review this plan and related documents
2. Check issue tracker for known problems
3. Consult existing script comments
4. Test in isolation before applying to system

---

**Ready to begin?** Start with Phase 1 in the [Implementation Plan](implementation-plan.md).