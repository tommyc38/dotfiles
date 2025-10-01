# Architecture Compatibility Guide

## Overview

All scripts and configuration files must work correctly on both Intel and Apple Silicon Macs. The primary differences involve Homebrew installation paths and some package availability.

## Architecture Differences

### Homebrew Paths

| Architecture | Homebrew Prefix | Typical Installation |
|--------------|-----------------|---------------------|
| **Apple Silicon (M1/M2/M3)** | `/opt/homebrew` | Native ARM64 packages |
| **Intel (x86_64)** | `/usr/local` | x86_64 packages |

### Detection Method

The standard detection pattern used throughout the codebase:

```bash
if [[ -x "/opt/homebrew/bin/brew" ]]; then
    # Apple Silicon
    HOMEBREW_PREFIX="/opt/homebrew"
elif [[ -x "/usr/local/bin/brew" ]]; then
    # Intel
    HOMEBREW_PREFIX="/usr/local"
fi
```

## Current Implementation Status

### ✅ Files Already Handling Architecture

#### 1. bash/bash_profile.symlink (Lines 11-54)
```bash
if [[ "$(uname)" == "Darwin" && "$(command -v brew)" ]]; then
  if [[ -z "$HOMEBREW_PREFIX" ]]; then
    if [[ -x "/opt/homebrew/bin/brew" ]]; then
      # Apple Silicon Macs
      HOMEBREW_PREFIX="/opt/homebrew"
      export PATH="$HOMEBREW_PREFIX/bin:$PATH"
      export PATH="$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin:$PATH"
      # ... more paths
    elif [[ -x "/usr/local/bin/brew" ]]; then
      # Intel Macs
      HOMEBREW_PREFIX="/usr/local"
      export PATH="/usr/local/bin:$PATH"
      # ... more paths
    fi
  fi
fi
```

**Status**: ✅ Excellent - Handles both architectures with appropriate path configuration

#### 2. bash/bashrc.symlink (Lines 26-35)
```bash
if [[ -z "$HOMEBREW_PREFIX" ]]; then
  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    HOMEBREW_PREFIX="/opt/homebrew"
    export PATH="$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin:$PATH"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    HOMEBREW_PREFIX="/usr/local"
  fi
fi
```

**Status**: ✅ Good - Basic detection in place

#### 3. zsh/zshrc.symlink (Lines 37-49)
```bash
if [[ "$(uname)" == "Darwin" && "$(command -v brew)" ]]; then
  if [[ -z "$HOMEBREW_PREFIX" ]]; then
    if [[ -x "/opt/homebrew/bin/brew" ]]; then
      # Apple Silicon Macs
      HOMEBREW_PREFIX="/opt/homebrew"
      export PATH="$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin:$PATH"
    elif [[ -x "/usr/local/bin/brew" ]]; then
      # Intel Macs
      HOMEBREW_PREFIX="/usr/local"
      export PATH="/usr/local/bin:$PATH"
    fi
  fi
fi
```

**Status**: ✅ Good - Handles both architectures

#### 4. install.sh (Lines 55-65)
```bash
# Detect Homebrew prefix
if [[ -x "/opt/homebrew/bin/brew" ]]; then
  BREW_PREFIX="/opt/homebrew"
else
  BREW_PREFIX="/usr/local"
fi

[ -z "$(cat < /etc/shells | grep "${BREW_PREFIX}/bin/bash")" ] && echo "${BREW_PREFIX}/bin/bash" >> /etc/shells
[ -z "$(cat < /etc/shells | grep "${BREW_PREFIX}/bin/zsh")" ] && echo "${BREW_PREFIX}/bin/zsh" >> /etc/shells
chsh -s "${BREW_PREFIX}/bin/zsh" "$SUDO_USER"
```

**Status**: ⚠️ Works but uses inconsistent naming (`BREW_PREFIX` instead of `HOMEBREW_PREFIX`)
**Action**: Rename `BREW_PREFIX` to `HOMEBREW_PREFIX` for consistency

#### 5. install/vagrant.sh (Lines 96-103)
```bash
# Detect if running on Apple Silicon, even if shell is under Rosetta
is_rosetta="$(sysctl -in sysctl.proc_translated 2>/dev/null)"
arch="$(uname -m)"
if [ "$arch" = "arm64" ] || [ "$is_rosetta" = "1" ]; then
  extension_pack_url="$extension_pack_url_apple"
else
  extension_pack_url="$extension_pack_url_intel"
fi
```

**Status**: ✅ Excellent - Handles both architectures, even detects Rosetta

### ⚠️ Files Needing Review

#### 1. bin/vault
**Current Status**: No architecture-specific code needed
**Reason**: Pure bash operations, no dependency on Homebrew paths
**Action**: ✅ No changes needed, but uses gnu-getopt

**Note**: Lines 177-188 use Homebrew getopt:
```bash
if [ "$(uname)" == "Darwin" ]; then
  if [ -e "$(brew --prefix)/opt/gnu-getopt/bin/getopt" ]; then
    options=$("$(brew --prefix)/opt/gnu-getopt/bin/getopt" -l "$long" -o "$short" -- "$@")
  else
    echo "This script requires the latest getopt command. Upgrade with: brew install gnu-getopt"
    exit 1
  fi
else
  options=$(getopt -l "$long" -o "$short" -a -- "$@")
fi
```

**Issue**: Uses `$(brew --prefix)` which automatically detects architecture ✅
**Status**: ✅ Already compatible

#### 2. bin/workenv.sh
**Current Code** (Lines 177-185):
```bash
if [ "$(uname)" = "Darwin" ]; then
  if [ -e "/usr/local/opt/gnu-getopt/bin/getopt" ]; then
    options=$(/usr/local/opt/gnu-getopt/bin/getopt -l "$long" -o "$short" -- "$@")
  else
    echo "This script requires the latest getopt command. Upgrade with: brew install gnu-getopt"
  fi
else
  options=$(getopt -l "$long" -o "$short" -a -- "$@")
fi
```

**Issue**: ⚠️ **CRITICAL - Hardcoded `/usr/local`** - Won't work on Apple Silicon
**Priority**: Critical
**Fix Needed**: Use standard HOMEBREW_PREFIX detection pattern

**Fixed Code** (using standard pattern):
```bash
if [ "$(uname)" = "Darwin" ]; then
  # Detect Homebrew prefix using standard pattern
  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    HOMEBREW_PREFIX="/opt/homebrew"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    HOMEBREW_PREFIX="/usr/local"
  fi
  
  if [ -e "$HOMEBREW_PREFIX/opt/gnu-getopt/bin/getopt" ]; then
    options=$("$HOMEBREW_PREFIX/opt/gnu-getopt/bin/getopt" -l "$long" -o "$short" -- "$@")
  else
    echo "This script requires the latest getopt command. Upgrade with: brew install gnu-getopt"
    exit 1
  fi
else
  options=$(getopt -l "$long" -o "$short" -a -- "$@")
fi
```

#### 3. bin/fonts.sh
**Current Code** (Lines 565-575):
```bash
if [ "$(uname)" == "Darwin" ]; then
  if [ -e "$(brew --prefix)/opt/gnu-getopt/bin/getopt" ]; then
    options=$("$(brew --prefix)/opt/gnu-getopt/bin/getopt" -l "$long" -o "$short" -- "$@")
  else
    echo "This script requires the latest getopt command. Upgrade with:"
    echo "  brew install gnu-getopt"
    exit 1
  fi
else
  options=$(getopt -l "$long" -o "$short" -a -- "$@")
fi
```

**Status**: ✅ Compatible (uses $(brew --prefix))
**Note**: Should be updated to use standard pattern for consistency

## Standard Pattern to Use (REQUIRED FOR ALL SCRIPTS)

### The Official Pattern

**ALL scripts and configuration files MUST use this pattern for consistency:**

```bash
# STANDARD HOMEBREW PATH DETECTION
# Use this pattern in ALL files - shell configs, install scripts, bin scripts, etc.

if [[ -x "/opt/homebrew/bin/brew" ]]; then
  # Apple Silicon Macs
  HOMEBREW_PREFIX="/opt/homebrew"
elif [[ -x "/usr/local/bin/brew" ]]; then
  # Intel Macs
  HOMEBREW_PREFIX="/usr/local"
else
  echo "Error: Homebrew not found" >&2
  exit 1
fi
```

**Why this pattern?**
1. ✅ Works everywhere (shell configs, scripts, all contexts)
2. ✅ Works even if brew isn't in PATH yet (early initialization)
3. ✅ No subprocess needed (faster)
4. ✅ Explicit and easy to understand
5. ✅ Consistent with current bash_profile and zshrc patterns

### Using the Detected Prefix

```bash
# After detection, ALWAYS use the $HOMEBREW_PREFIX variable
export PATH="$HOMEBREW_PREFIX/bin:$PATH"
export PATH="$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin:$PATH"

# For package-specific paths
if [ -e "$HOMEBREW_PREFIX/opt/gnu-getopt/bin/getopt" ]; then
  options=$("$HOMEBREW_PREFIX/opt/gnu-getopt/bin/getopt" -l "$long" -o "$short" -- "$@")
fi

# For package locations
GETOPT_PATH="$HOMEBREW_PREFIX/opt/gnu-getopt/bin/getopt"
```

### ❌ DO NOT USE These Patterns

```bash
# ❌ Don't use $(brew --prefix) - requires brew in PATH, spawns subprocess
HOMEBREW_PREFIX="$(brew --prefix)"

# ❌ Don't hardcode paths
export PATH="/usr/local/bin:$PATH"
export PATH="/opt/homebrew/bin:$PATH"

# ❌ Don't use command -v brew for path detection
if command -v brew >/dev/null 2>&1; then
  HOMEBREW_PREFIX="$(brew --prefix)"
fi
```

**Exception**: It's acceptable to use `$(brew --prefix)` for one-off command execution IF Homebrew is definitely available and you don't need the prefix variable:
```bash
# Acceptable for one-time use (but variable is still preferred)
source "$(brew --prefix)/etc/profile.d/bash_completion.sh"
```

### 3. Architecture-Specific Logic (When Needed)

```bash
# Get actual architecture (handles Rosetta)
arch="$(uname -m)"
is_rosetta="$(sysctl -in sysctl.proc_translated 2>/dev/null)"

if [ "$arch" = "arm64" ] || [ "$is_rosetta" = "1" ]; then
  # Apple Silicon specific code
  echo "Running on Apple Silicon"
else
  # Intel specific code
  echo "Running on Intel"
fi
```

## Required Changes

### Critical Fix: bin/workenv.sh

**Current Code** (Lines 177-185):
```bash
if [ "$(uname)" = "Darwin" ]; then
  if [ -e "/usr/local/opt/gnu-getopt/bin/getopt" ]; then
    options=$(/usr/local/opt/gnu-getopt/bin/getopt -l "$long" -o "$short" -- "$@")
```

**Fixed Code**:
```bash
if [ "$(uname)" = "Darwin" ]; then
  if [ -e "$(brew --prefix)/opt/gnu-getopt/bin/getopt" ]; then
    options=$("$(brew --prefix)/opt/gnu-getopt/bin/getopt" -l "$long" -o "$short" -- "$@")
```

## Testing Requirements

### Test on Both Architectures

All scripts must be tested on:
1. ✅ **Intel Mac** (x86_64, /usr/local)
2. ✅ **Apple Silicon Mac** (ARM64, /opt/homebrew)
3. ✅ **Apple Silicon Mac under Rosetta** (x86_64 emulation)

### Test Cases

```bash
# 1. Verify Homebrew prefix detection
echo "Homebrew prefix: $(brew --prefix)"
# Expected: /opt/homebrew (Apple Silicon) or /usr/local (Intel)

# 2. Verify PATH includes correct Homebrew binary
which brew
# Expected: /opt/homebrew/bin/brew or /usr/local/bin/brew

# 3. Verify coreutils are accessible
which readlink
# Expected: Homebrew's GNU readlink, not macOS BSD version

# 4. Verify getopt is accessible
which getopt
# Expected: $(brew --prefix)/opt/gnu-getopt/bin/getopt

# 5. Test script execution
./bin/workenv.sh --help
# Expected: No errors about missing getopt
```

## Package Availability

### Packages Available on Both

Most Homebrew packages are available on both architectures:
- ✅ coreutils
- ✅ gnu-getopt
- ✅ bash
- ✅ zsh
- ✅ git
- ✅ vim/neovim
- ✅ node (via nvm)
- ✅ python (via pyenv)

### Potential Issues

Some casks or specific versions might have limited availability:
- ⚠️ VirtualBox Extension Pack (different downloads for each architecture)
- ⚠️ Some older packages may not be compiled for ARM64

**Solution**: Always check package availability and provide fallbacks

## Implementation Checklist

### Phase 1: Critical Fixes

- [x] ✅ bash/bash_profile.symlink - Uses standard pattern with HOMEBREW_PREFIX
- [x] ✅ bash/bashrc.symlink - Uses standard pattern with HOMEBREW_PREFIX
- [x] ✅ zsh/zshrc.symlink - Uses standard pattern with HOMEBREW_PREFIX
- [ ] ⚠️ install.sh - Uses `BREW_PREFIX` (rename to HOMEBREW_PREFIX)
- [x] ✅ install/vagrant.sh - Uses standard pattern
- [ ] 🔴 bin/workenv.sh - **CRITICAL FIX NEEDED** (hardcoded /usr/local)

### Phase 2: Consistency Updates

#### Naming Convention Fix
- [ ] install.sh - Rename `BREW_PREFIX` to `HOMEBREW_PREFIX` (lines 55-65)

#### Pattern Standardization (Optional but Recommended)
- [ ] bin/vault - Update to use standard pattern (currently uses $(brew --prefix))
- [ ] bin/fonts.sh - Update to use standard pattern (currently uses $(brew --prefix))
- [ ] Review all other bin/ scripts for consistency

### Phase 2: Testing

- [ ] Test on Intel Mac
- [ ] Test on Apple Silicon Mac
- [ ] Test under Rosetta
- [ ] Verify all Homebrew package paths
- [ ] Verify all GNU tools are accessible

### Phase 3: Documentation

- [ ] Update README with architecture requirements
- [ ] Document testing procedures
- [ ] Add troubleshooting for architecture issues

## Common Pitfalls to Avoid

### ❌ Don't Do This

```bash
# Hardcoded path - breaks on Apple Silicon
export PATH="/usr/local/bin:$PATH"

# Hardcoded tool location
/usr/local/opt/gnu-getopt/bin/getopt

# Assuming architecture
if [[ "$(uname -m)" == "x86_64" ]]; then
  # This fails on Apple Silicon under Rosetta
fi
```

### ✅ Do This Instead

```bash
# Use dynamic detection
export PATH="$(brew --prefix)/bin:$PATH"

# Or use variable
export PATH="$HOMEBREW_PREFIX/bin:$PATH"

# Use tool location from brew
"$(brew --prefix)/opt/gnu-getopt/bin/getopt"

# Check for actual Rosetta or native ARM
is_rosetta="$(sysctl -in sysctl.proc_translated 2>/dev/null)"
if [ "$is_rosetta" = "1" ]; then
  # Running under Rosetta
fi
```

## Summary

**Current Status**:
- ✅ Most files already handle architecture correctly
- ⚠️ **One critical fix needed**: bin/workenv.sh has hardcoded `/usr/local`
- ✅ Good patterns already established in bash/zsh configs
- ✅ install.sh properly detects architecture

**Action Items**:
1. Fix bin/workenv.sh to use `$(brew --prefix)` instead of `/usr/local`
2. Review all bin/ scripts for hardcoded paths
3. Test on both architectures
4. Document architecture compatibility in README

**Priority**: High - Fix workenv.sh immediately as it's actively used