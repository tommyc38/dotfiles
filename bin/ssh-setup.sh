#!/bin/bash

# MIT License
#
# Copyright (c) 2023 Tom Conley
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# SSH Setup Script
# - Reads SSH key list from vault-key/ssh-keys.txt
# - Ensures .ssh directory exists with proper permissions
# - Starts ssh-agent if needed
# - Adds specified private keys from ~/.ssh/ to agent
# - Uses macOS keychain for persistence

# Find dotfiles directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VAULT_KEY_DIR="$DOTFILES_DIR/vault-key"
SSH_DIR="$HOME/.ssh"
SSH_KEYS_CONFIG="$VAULT_KEY_DIR/ssh-keys.txt"

# Only run if vault-key directory exists (keys are decrypted)
if [ ! -d "$VAULT_KEY_DIR" ]; then
  return 0 2>/dev/null || exit 0
fi

# Check if ssh-keys.txt config file exists
if [ ! -f "$SSH_KEYS_CONFIG" ]; then
  echo "⚠️  No ssh-keys.txt config file found in vault-key/"
  echo "   Create $SSH_KEYS_CONFIG to specify which keys to add to agent"
  return 0 2>/dev/null || exit 0
fi

# Ensure .ssh directory exists with proper permissions
if [ ! -d "$SSH_DIR" ]; then
  mkdir -p "$SSH_DIR"
  chmod 700 "$SSH_DIR"
  echo "Created $SSH_DIR directory"
fi

# Verify .ssh directory has correct permissions
if [ "$(stat -f %A "$SSH_DIR" 2>/dev/null || stat -c %a "$SSH_DIR" 2>/dev/null)" != "700" ]; then
  chmod 700 "$SSH_DIR"
fi

# Function to check if ssh-agent is running and accessible
is_agent_running() {
  if [ -n "$SSH_AUTH_SOCK" ] && [ -S "$SSH_AUTH_SOCK" ]; then
    ssh-add -l &>/dev/null
    local status=$?
    # 0 = agent has keys, 1 = agent has no keys, 2 = cannot connect
    [ $status -eq 0 ] || [ $status -eq 1 ]
    return $?
  fi
  return 1
}

# Start ssh-agent if not running
if ! is_agent_running; then
  # Check if there's an existing agent we can connect to
  if [ "$(uname)" == "Darwin" ]; then
    # On macOS, try to find existing agent socket
    shopt -s nullglob 2>/dev/null || true
    for sock in /tmp/ssh-*/agent.*; do
      if [ -S "$sock" ]; then
        export SSH_AUTH_SOCK="$sock"
        if is_agent_running; then
          break
        fi
      fi
    done
    shopt -u nullglob 2>/dev/null || true
  fi
  
  # If still no agent, start a new one
  if ! is_agent_running; then
    eval "$(ssh-agent -s)" >/dev/null 2>&1
  fi
fi

# Function to check if a key is already loaded
is_key_loaded() {
  local key_file="$1"
  
  # Check if the key file exists and is readable
  if [ ! -f "$key_file" ] && [ ! -L "$key_file" ]; then
    return 1
  fi
  
  # Get the fingerprint of the key file
  local key_fingerprint
  key_fingerprint=$(ssh-keygen -lf "$key_file" 2>/dev/null | awk '{print $2}')
  
  if [ -z "$key_fingerprint" ]; then
    return 1
  fi
  
  # Check if this fingerprint is in the loaded keys
  ssh-add -l 2>/dev/null | grep -q "$key_fingerprint"
  return $?
}

# Function to add a key to the agent
add_key_to_agent() {
  local key_path="$1"
  local key_name="$2"
  
  # Check if key file exists (could be symlink)
  if [ ! -f "$key_path" ] && [ ! -L "$key_path" ]; then
    echo "  ✗ $key_name (file not found at $key_path)"
    return 1
  fi
  
  # Validate it's a valid SSH key
  if ! ssh-keygen -l -f "$key_path" &>/dev/null; then
    echo "  ✗ $key_name (not a valid SSH key)"
    return 1
  fi
  
  # Check if key is already loaded
  if is_key_loaded "$key_path"; then
    echo "  ✓ $key_name (already loaded)"
    return 0
  fi
  
  # Add the key
  if [ "$(uname)" == "Darwin" ]; then
    # macOS: Use keychain integration
    if ssh-add --help 2>&1 | grep -q "apple-use-keychain"; then
      ssh-add --apple-use-keychain "$key_path" 2>/dev/null
    else
      # Fallback for older macOS versions
      ssh-add -K "$key_path" 2>/dev/null
    fi
  else
    # Linux
    ssh-add "$key_path" 2>/dev/null
  fi
  
  if [ $? -eq 0 ]; then
    echo "  ✓ $key_name (added to agent)"
    return 0
  else
    echo "  ✗ $key_name (failed to add - check passphrase or permissions)"
    return 1
  fi
}

# Read ssh-keys.txt and add each key
added_any=false
keys_processed=0
keys_added=0

# Parse the config file (skip comments and empty lines)
while IFS= read -r key_name || [ -n "$key_name" ]; do
  # Skip comments and empty lines
  [[ "$key_name" =~ ^#.*$ ]] && continue
  [[ -z "$key_name" ]] && continue
  
  # Trim whitespace
  key_name=$(echo "$key_name" | xargs)
  
  if [ ! "$added_any" = true ]; then
    echo "Adding SSH keys to agent..."
    added_any=true
  fi
  
  # Full path to key in .ssh directory
  key_path="$SSH_DIR/$key_name"
  
  # Add this key
  if add_key_to_agent "$key_path" "$key_name"; then
    ((keys_added++))
  fi
  ((keys_processed++))
  
done < "$SSH_KEYS_CONFIG"

# Summary
if [ "$added_any" = true ]; then
  echo ""
  echo "SSH setup complete: $keys_added/$keys_processed keys loaded"
  
  # Show current keys
  echo ""
  echo "Currently loaded SSH keys:"
  ssh-add -l 2>/dev/null || echo "  (none)"
fi

# Export SSH_AUTH_SOCK for this shell session
if [ -n "$SSH_AUTH_SOCK" ]; then
  export SSH_AUTH_SOCK
fi