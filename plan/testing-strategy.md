# Testing Strategy for Dotfiles Repository

## Overview

This document outlines the testing approach for the dotfiles repository, allowing validation of all scripts without requiring VMs, Docker, or affecting the actual system.

## Testing Philosophy

### Key Principles

1. **Non-Destructive**: Tests should never modify the actual system
2. **Isolated**: Each test should run in isolation
3. **Reproducible**: Tests should produce consistent results
4. **Fast**: Tests should run quickly to encourage frequent testing
5. **Comprehensive**: Cover all critical functionality

### Approach

Instead of using VMs or Docker, we'll use:
- Mock directories to simulate filesystem operations
- Dry-run modes in scripts
- Function interception to prevent actual system changes
- Validation without execution

## Test Directory Structure

```
test/
├── README.md                    # Testing documentation
├── test-framework.sh            # Main test harness
├── lib/
│   ├── mock-commands.sh        # Mock system commands
│   ├── assertions.sh           # Test assertions
│   └── helpers.sh              # Common test utilities
├── fixtures/
│   ├── sample-configs/         # Sample configuration files
│   ├── test-vault/             # Test vault files
│   └── expected-outputs/       # Expected test results
├── unit/
│   ├── test-symlinks.sh        # Symlink functionality tests
│   ├── test-vault.sh           # Vault encryption/decryption tests
│   ├── test-fonts.sh           # Font installation tests
│   └── test-install.sh         # Main install script tests
├── integration/
│   ├── test-full-install.sh    # End-to-end installation test
│   └── test-workflows.sh       # Common workflow tests
├── mock-environment/
│   ├── home/                   # Mock home directory
│   ├── etc/                    # Mock system directories
│   └── Applications/           # Mock Applications folder
└── results/
    ├── logs/                   # Test execution logs
    └── reports/                # Test reports
```

## Testing Modes

### 1. Dry-Run Testing

**Purpose**: Validate script logic without making changes

**Implementation**:
```bash
# Add to all scripts
if [ -n "$DRY_RUN" ]; then
    echo "[DRY-RUN] Would execute: $command"
    return 0
fi
```

**Usage**:
```bash
DRY_RUN=1 ./install.sh
./bin/symlink.sh --dry-run
```

### 2. Mock Environment Testing

**Purpose**: Run scripts against mock directories instead of real system

**Implementation**:
```bash
# Set test environment variables
export TEST_MODE=1
export TEST_HOME="$PWD/test/mock-environment/home"
export TEST_SYSTEM_ROOT="$PWD/test/mock-environment"

# Scripts check for test mode
if [ -n "$TEST_MODE" ]; then
    HOME="$TEST_HOME"
    # Use mock directories
fi
```

**Example Mock Structure**:
```
test/mock-environment/
├── home/
│   ├── .bash_profile
│   ├── .bashrc
│   ├── .zshrc
│   └── dotfiles/           # Clone of repository
├── etc/
│   └── shells
├── Library/
│   └── Fonts/
└── Applications/
```

### 3. Function Interception Testing

**Purpose**: Prevent actual system modifications by mocking commands

**Implementation**:
```bash
# In test/lib/mock-commands.sh

# Mock brew command
brew() {
    echo "[MOCK] brew $*" >&2
    case "$1" in
        install)
            echo "Installing ${*:2}..."
            return 0
            ;;
        --prefix)
            echo "/opt/homebrew"
            ;;
    esac
}

# Mock curl
curl() {
    echo "[MOCK] curl $*" >&2
    if [[ "$*" == *"-o"* ]]; then
        local output_file
        # Parse output file from arguments
        touch "$output_file"
    fi
    return 0
}

# Export mock functions
export -f brew curl
```

**Usage**:
```bash
source test/lib/mock-commands.sh
./install/brew.sh
```

## Test Framework Implementation

### Core Test Harness

**File**: `test/test-framework.sh`

```bash
#!/bin/bash

# Test Framework
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
CURRENT_SUITE=""

# Setup test environment
setup_test_env() {
    echo "Setting up test environment..."
    
    # Create mock directories
    mkdir -p test/mock-environment/{home,etc,Library/Fonts,Applications}
    mkdir -p test/results/{logs,reports}
    
    # Set environment variables
    export TEST_MODE=1
    export TEST_HOME="$PWD/test/mock-environment/home"
    export DRY_RUN=1
    
    # Source mock commands
    source test/lib/mock-commands.sh
}

# Teardown test environment
teardown_test_env() {
    echo "Cleaning up test environment..."
    # Optionally remove mock directories
    # rm -rf test/mock-environment
}

# Test assertion functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Assertion failed}"
    
    ((TESTS_RUN++))
    
    if [ "$expected" = "$actual" ]; then
        ((TESTS_PASSED++))
        echo -e "${GREEN}✓${NC} $message"
        return 0
    else
        ((TESTS_FAILED++))
        echo -e "${RED}✗${NC} $message"
        echo "  Expected: $expected"
        echo "  Actual: $actual"
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local message="${2:-File should exist: $file}"
    
    ((TESTS_RUN++))
    
    if [ -e "$file" ]; then
        ((TESTS_PASSED++))
        echo -e "${GREEN}✓${NC} $message"
        return 0
    else
        ((TESTS_FAILED++))
        echo -e "${RED}✗${NC} $message"
        return 1
    fi
}

# Run a test suite
run_suite() {
    local suite_name="$1"
    local suite_file="$2"
    
    echo ""
    echo "═══════════════════════════════════════"
    echo "Running Test Suite: $suite_name"
    echo "═══════════════════════════════════════"
    
    CURRENT_SUITE="$suite_name"
    
    # Source and run the test file
    source "$suite_file"
}

# Print test results
print_results() {
    echo ""
    echo "═══════════════════════════════════════"
    echo "Test Results"
    echo "═══════════════════════════════════════"
    echo "Total: $TESTS_RUN"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    
    if [ $TESTS_FAILED -gt 0 ]; then
        echo -e "${RED}Failed: $TESTS_FAILED${NC}"
        return 1
    else
        echo "All tests passed!"
        return 0
    fi
}

# Main execution
main() {
    setup_test_env
    
    # Run all test suites
    run_suite "Symlink Tests" "test/unit/test-symlinks.sh"
    run_suite "Vault Tests" "test/unit/test-vault.sh"
    run_suite "Install Tests" "test/unit/test-install.sh"
    
    # Optionally run integration tests
    if [ "${RUN_INTEGRATION:-0}" = "1" ]; then
        run_suite "Integration Tests" "test/integration/test-full-install.sh"
    fi
    
    print_results
    local exit_code=$?
    
    teardown_test_env
    
    exit $exit_code
}

main "$@"
```

## Specific Test Implementations

### 1. Symlink Tests

**File**: `test/unit/test-symlinks.sh`

**What to Test**:
- Symlink creation in mock directory
- Backup of existing files
- Restore functionality
- Dry-run mode
- Error handling for invalid paths
- Handling of already-symlinked files

**Example Tests**:
```bash
test_symlink_creation() {
    # Setup
    local source="$TEST_HOME/dotfiles/bash/bashrc.symlink"
    local target="$TEST_HOME/.bashrc"
    echo "test content" > "$source"
    
    # Execute
    ./bin/symlink.sh --dry-run
    
    # Assert
    assert_file_exists "$source" "Source file should exist"
}

test_backup_existing_file() {
    # Setup
    local target="$TEST_HOME/.bashrc"
    echo "original content" > "$target"
    
    # Execute (in test mode)
    TEST_MODE=1 ./bin/symlink.sh
    
    # Assert
    assert_file_exists "$TEST_HOME/dotfiles_backup/.bashrc" "Backup should exist"
}
```

### 2. Vault Tests

**File**: `test/unit/test-vault.sh`

**What to Test**:
- Encryption of test files
- Decryption of test files
- Password handling
- Backup functionality
- List functionality

**Example Tests**:
```bash
test_vault_encryption() {
    # Setup
    local test_file="test/fixtures/test-vault/test-secret.txt"
    echo "secret content" > "$test_file"
    local password="test-password"
    
    # Execute
    echo "$password" | ./bin/vault --encrypt
    
    # Assert
    assert_file_exists "vault/encrypted-file" "Encrypted file should exist"
}
```

### 3. Install Script Tests

**File**: `test/unit/test-install.sh`

**What to Test**:
- Script syntax validation
- Sudo requirement detection
- Environment variable handling
- Dependency checking
- Error handling
- Progress through stages

**Example Tests**:
```bash
test_install_syntax() {
    # Validate bash syntax
    bash -n install.sh
    assert_equals 0 $? "install.sh should have valid syntax"
}

test_install_dry_run() {
    # Execute in dry-run mode
    DRY_RUN=1 ./install.sh
    
    # Assert no files were modified
    # Check that log shows what would happen
}
```

### 4. Integration Tests

**File**: `test/integration/test-full-install.sh`

**What to Test**:
- Complete installation workflow in mock environment
- Script execution order
- Environment setup
- Post-installation validation

## Test Execution

### Running Tests

```bash
# Run all tests
./test/test-framework.sh

# Run specific test suite
./test/unit/test-symlinks.sh

# Run with integration tests
RUN_INTEGRATION=1 ./test/test-framework.sh

# Run with verbose output
VERBOSE=1 ./test/test-framework.sh

# Run and save results
./test/test-framework.sh | tee test/results/$(date +%Y%m%d-%H%M%S).log
```

### CI/CD Integration

```yaml
# .github/workflows/test.yml
name: Test Dotfiles

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run Tests
        run: |
          chmod +x test/test-framework.sh
          ./test/test-framework.sh
```

## Validation Scripts

### Post-Installation Validation

**File**: `test/validate-installation.sh`

```bash
#!/bin/bash

# Validate installation without making changes
echo "Validating installation..."

# Check for required commands
for cmd in brew git vim nvim zsh; do
    if command -v $cmd >/dev/null 2>&1; then
        echo "✓ $cmd found"
    else
        echo "✗ $cmd not found"
    fi
done

# Check for symlinks
for link in ~/.zshrc ~/.bashrc ~/.bash_profile; do
    if [ -L "$link" ]; then
        echo "✓ $link is symlinked"
    else
        echo "✗ $link is not symlinked"
    fi
done

# Check for installed fonts
# Check for NVM
# Check for Python versions
# etc.
```

## Best Practices

### 1. Test Isolation
- Each test should be independent
- Clean up after tests
- Don't rely on test execution order

### 2. Mock Data
- Use realistic test data
- Store test fixtures in `test/fixtures/`
- Document what each fixture represents

### 3. Error Cases
- Test both success and failure paths
- Test edge cases
- Test with invalid inputs

### 4. Documentation
- Document what each test validates
- Explain why tests exist
- Update tests when requirements change

### 5. Performance
- Keep tests fast
- Use parallelization when possible
- Profile slow tests

## Troubleshooting Tests

### Common Issues

**Test fails intermittently**
- Check for race conditions
- Ensure proper cleanup
- Check for shared state

**Test passes but script fails in production**
- Mocks may not match reality
- Add integration tests
- Test on actual system (carefully)

**Tests are slow**
- Profile test execution
- Parallelize independent tests
- Use smaller test datasets

## Future Enhancements

### Potential Additions

1. **Property-based Testing**: Generate random inputs
2. **Coverage Reporting**: Track which code paths are tested
3. **Performance Benchmarks**: Track script execution time
4. **Mutation Testing**: Verify tests catch bugs
5. **Container Testing**: Optional Docker-based testing

## Summary

This testing strategy provides:

✅ **Safety**: Test without affecting the system
✅ **Speed**: Fast test execution
✅ **Confidence**: Comprehensive coverage
✅ **Maintainability**: Easy to add new tests
✅ **CI/CD Ready**: Can run in automation

The combination of dry-run modes, mock environments, and function interception allows thorough testing of all dotfiles functionality without requiring VMs or risking system stability.