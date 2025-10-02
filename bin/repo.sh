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

script="$(basename "$0")"
dry_run=
default_directory=
source_file=
npm_install=

# We need to have access to nvm
export NVM_DIR=$HOME/.nvm;
source $NVM_DIR/nvm.sh;

# Detect and install the appropriate Node version and package manager, then install packages
function npm_install() {
  local directory="$1"
  local nvmrc_file="$directory/.nvmrc"
  local package_json="$directory/package.json"
  local node_version=""
  local package_manager=""
  local install_command=""
  
  # Only proceed if --npm-install flag is set and package.json exists
  if [ -z "$npm_install" ] || [ ! -f "$package_json" ]; then
    return 0
  fi
  
  # Skip if node_modules already exists
  if [ -d "$directory/node_modules" ] && [ -n "$(ls -A "$directory/node_modules" 2>/dev/null)" ]; then
    echo "  Packages already installed in $(basename "$directory"), skipping"
    return 0
  fi
  
  echo ""
  echo "  Installing packages for $(basename "$directory")..."
  
  # Step 1: Determine required Node version
  if [ -f "$nvmrc_file" ]; then
    node_version=$(cat "$nvmrc_file" | tr -d '[:space:]')
    echo "    Found .nvmrc: $node_version"
  else
    # Try to extract from package.json engines.node field
    if command -v node >/dev/null 2>&1; then
      node_version=$(node -pe "try { const pkg = require('$package_json'); pkg.engines && pkg.engines.node || '' } catch(e) { '' }" 2>/dev/null || echo "")
    fi
    
    if [ -n "$node_version" ]; then
      echo "    Found Node version in package.json engines: $node_version"
    else
      echo "    ⚠️  No .nvmrc or package.json engines.node found"
      echo "    Skipping package installation (cannot determine Node version)"
      return 1
    fi
  fi
  
  # Step 2: Install Node version if needed (handle version ranges)
  if [ -n "$node_version" ]; then
    # Extract just the major version for simple cases like "20" or "20.x"
    local major_version=$(echo "$node_version" | grep -oE '[0-9]+' | head -1)
    
    if [ -n "$major_version" ]; then
      # Check if this version is installed
      if ! nvm ls "$major_version" >/dev/null 2>&1; then
        echo "    Installing Node.js v$major_version..."
        if [ -z "$dry_run" ]; then
          nvm install "$major_version" >/dev/null 2>&1
          if [ $? -ne 0 ]; then
            echo "    ✗ Failed to install Node.js v$major_version"
            return 1
          fi
        fi
      fi
      
      # Use this Node version
      echo "    Using Node.js v$major_version"
      if [ -z "$dry_run" ]; then
        nvm use "$major_version" >/dev/null 2>&1
      fi
    fi
  fi
  
  # Step 3: Detect package manager from lock files
  if [ -f "$directory/pnpm-lock.yaml" ]; then
    package_manager="pnpm"
    install_command="pnpm install"
  elif [ -f "$directory/yarn.lock" ]; then
    package_manager="yarn"
    install_command="yarn install"
  elif [ -f "$directory/package-lock.json" ]; then
    package_manager="npm"
    install_command="npm install"
  else
    # No lock file, check package.json for packageManager field
    if command -v node >/dev/null 2>&1; then
      local pkg_manager=$(node -pe "try { const pkg = require('$package_json'); pkg.packageManager || '' } catch(e) { '' }" 2>/dev/null || echo "")
      if [ -n "$pkg_manager" ]; then
        package_manager=$(echo "$pkg_manager" | cut -d'@' -f1)
        install_command="$package_manager install"
      else
        package_manager="npm"
        install_command="npm install"
      fi
    else
      echo "    ⚠️  Cannot detect package manager (Node not available)"
      return 1
    fi
  fi
  
  echo "    Detected package manager: $package_manager"
  
  # Step 4: Ensure package manager is installed globally for this Node version
  if [ "$package_manager" != "npm" ]; then
    if ! command -v "$package_manager" >/dev/null 2>&1; then
      echo "    Installing $package_manager globally..."
      if [ -z "$dry_run" ]; then
        npm install -g "$package_manager" >/dev/null 2>&1
        if [ $? -ne 0 ]; then
          echo "    ✗ Failed to install $package_manager globally"
          echo "    Falling back to npm"
          package_manager="npm"
          install_command="npm install"
        fi
      fi
    fi
  fi
  
  # Step 5: Run the install
  if [ -z "$dry_run" ]; then
    echo "    Running: $install_command"
    cd "$directory" || return 1
    
    if $install_command; then
      echo "    ✓ Packages installed successfully"
      cd - >/dev/null || return 0
      return 0
    else
      echo "    ✗ Package installation failed"
      cd - >/dev/null || return 1
      return 1
    fi
  else
    echo "    [DRY RUN] Would run: $install_command"
  fi
}

# Clone each entry in the source file.
function clone_repos() {
  local line
  local repo
  local repo_name
  local directory
  local line_count
  local count=1
  local install_dir
  local sed_pattern='/^\s*#/d;/^\s*$/d' # Delete blank lines or commented lines.
  line_count="$(cat "$source_file" | sed "$sed_pattern" | wc -l)"

  while IFS= read -r line; do

    # Split string into two variables if it contains a space.
    if [[ "$line" == *" "* ]]; then
      read -r repo directory <<< "$line"
    else
      repo="$line"
      directory=""  # Clear directory so it uses default_directory
    fi

    repo_name="$(basename "$repo" | sed 's/\.git$//')"
    directory=${directory//'$HOME'/$HOME}
    directory=${directory//'~'/$HOME}
    directory=${directory:-$default_directory}

    # Check if the target directory is itself a git repository
    # If it is, clone directly to it. Otherwise, append repo name.
    if [ -e "$directory/.git" ]; then
      # Directory exists and is a git repo - use it directly
      install_dir="$directory"
    else
      # Directory doesn't exist or isn't a git repo - append repo name
      install_dir="$directory/$repo_name"
    fi

    if [ -z "$directory" ]; then
      echo "No destination directory supplied ($count/$line_count). Clone skipped! -- $repo"
    elif [ -e "$install_dir" ] && [ -n "$(ls -A "$install_dir")" ]; then
      # Directory exists - check if it's the correct git repository
      if [ -d "$install_dir/.git" ]; then
        # Get the remote URL from the existing repo
        local existing_remote
        existing_remote=$(cd "$install_dir" && git config --get remote.origin.url 2>/dev/null)
        
        # Normalize URLs for comparison (remove trailing .git, handle SSH vs HTTPS)
        local repo_normalized="${repo%.git}"
        local existing_normalized="${existing_remote%.git}"
        
        if [ "$repo_normalized" = "$existing_normalized" ]; then
          echo "Repository ~${install_dir//$HOME/} already cloned ($count/$line_count). Clone skipped! -- $repo"
          # If --npm-install is set and node_modules is missing, attempt to install dependencies
          npm_install "$install_dir"
        else
          echo "⚠️  Directory ~${install_dir//$HOME/} exists but contains different repository ($count/$line_count)"
          echo "    Expected: $repo"
          echo "    Found: $existing_remote"
          echo "    Skipping to avoid overwriting. -- $repo"
        fi
      else
        echo "⚠️  Directory ~${install_dir//$HOME/} exists but is not a git repository ($count/$line_count)"
        echo "    Skipping to avoid overwriting. -- $repo"
      fi
    else
      echo "Cloning ($count/$line_count) - $repo ~${install_dir//$HOME/}"
      # Create parent directory if it doesn't exist
      parent_dir="$(dirname "$install_dir")"
      if [ ! -d "$parent_dir" ]; then
        [ -z "$dry_run" ] && mkdir -p "$parent_dir"
        echo "Created parent directory: ~${parent_dir//$HOME/}"
      fi
      [ -z "$dry_run" ] && git clone "$repo" "$install_dir"
      npm_install "$install_dir"
    fi
    ((count++))

  done < <(sed "$sed_pattern" "$source_file")
}

# Show the script usage.
function usage() {
echo "
Usage:
  $script [-h|--help] [-d|--dry-run] [-i|--npm-install] [-D|--default-directory <directory>] [-f|--file <filename>]

Description:
  Clone multiple git repositories and optionally install their dependencies with intelligent
  Node version and package manager detection.

  Smart Package Installation (with --npm-install):
  - Detects required Node version from .nvmrc or package.json engines.node
  - Automatically installs missing Node versions via nvm
  - Detects package manager from lock files (pnpm-lock.yaml, yarn.lock, package-lock.json)
  - Auto-installs missing package managers (pnpm, yarn) globally
  - Falls back to npm if detection fails
  - Skips installation if requirements cannot be determined
  - Re-installs dependencies for existing repos if node_modules is missing or empty

Options:
  -h, --help                      Show this help message and exit.
  -d, --dry-run                   Show what would be done without actually doing it.
  -i, --npm-install               Install packages for each cloned repository.
                                  Requires package.json and either .nvmrc or engines.node.
  -D, --default-directory <dir>   Default directory for cloning repos (if not specified per repo).
                                  Supports \$HOME and ~ expansion. Created automatically if needed.
  -f, --file <file>               File containing repository URLs and optional target directories.

File Format:
  Each line: <repo-url> [target-directory]
  - Lines without directory use --default-directory
  - Comments start with #
  - Blank lines are ignored
  - Supports \$HOME and ~ expansion in paths

Examples:

  1. Basic cloning with default directory:
    repos.txt:
      git@github.com:org/repo1.git
      git@github.com:org/repo2.git
    
    $script --file repos.txt --default-directory \$HOME/projects
    
    Result:
      \$HOME/projects/repo1/
      \$HOME/projects/repo2/

  2. Mixed with custom directories:
    repos.txt:
      git@github.com:org/repo1.git \$HOME/custom/path
      git@github.com:org/repo2.git
      # This is a comment
      git@github.com:org/repo3.git
    
    $script --file repos.txt -D \$HOME/projects
    
    Result:
      \$HOME/custom/path/repo1/
      \$HOME/projects/repo2/
      \$HOME/projects/repo3/

  3. With package installation:
    $script --file repos.txt -D \$HOME/dev --npm-install
    
    For each repo with package.json:
      - Reads .nvmrc (e.g., \"20\") or package.json engines.node
      - Installs Node 20 if not present (via nvm install 20)
      - Detects pnpm/yarn/npm from lock files
      - Installs package manager if missing (e.g., npm install -g pnpm)
      - Runs package installation (pnpm install, yarn install, or npm install)

Package Installation Requirements:
  - Must have nvm installed and sourced
  - Repo must contain package.json
  - Repo must have .nvmrc OR package.json engines.node field
  - If requirements not met, installation is skipped with a warning

Supported Package Managers:
  - npm (default, always available)
  - yarn (auto-installed if yarn.lock found)
  - pnpm (auto-installed if pnpm-lock.yaml found)

Features:
  - Parent directories created automatically
  - Skips cloning if repo already exists (verified by git remote URL)
  - Re-installs packages for existing repos if node_modules missing (with --npm-install)
  - Never overwrites existing repos or unrelated directories
  - Warns if directory exists but contains different repository
  - Continues on errors (doesn't block other repos)
  - Works on both Intel and Apple Silicon Macs"
}

# Parse the options passed to the script.
function main() {
  local short="dhif:D:"
  local long="dry-run,npm-install,npm-install,help,default-directory:,file:"
  local options

  if [ "$(uname)" == "Darwin" ]; then
    # Detect Homebrew prefix for both Intel and Apple Silicon
    if [[ -x "/opt/homebrew/bin/brew" ]]; then
      HOMEBREW_PREFIX="/opt/homebrew"
    elif [[ -x "/usr/local/bin/brew" ]]; then
      HOMEBREW_PREFIX="/usr/local"
    fi
    
    if [ -e "$HOMEBREW_PREFIX/opt/gnu-getopt/bin/getopt" ]; then
      options=$("$HOMEBREW_PREFIX/opt/gnu-getopt/bin/getopt" -l "$long" -o "$short" -a -- "$@")
    else
      echo "This script requires the latest getopt command. Upgrade with:"
      echo "  brew install gnu-getopt"
      exit 1
    fi
  else
      options=$(getopt -l "$long" -o "$short" -a -- "$@")
  fi

  # Set the positional parameters to the parsed getopt command output.
  eval set -- "$options"

  while true; do
    case "$1" in

      -d|--dry-run|-dry-run) dry_run=true; shift;;
      -i|--npm-install|-npm-install) npm_install=true; shift;;
      -D|--default-directory|--default-directory) shift
        # Expand $HOME and ~ in the path
        default_directory="${1//'$HOME'/$HOME}"
        default_directory="${default_directory//'~'/$HOME}"
        # Don't require directory to exist - we'll create it when needed
        shift;;
      -f|--file|-file) shift
        source_file="$(readlink -f "$1")"
        if [ ! -e "$source_file" ];then
          echo "You must include a repo file. See --help."
          exit 1
        fi
        shift;;
      -h|--help|-help) usage; exit 0;;
      --) break;;
      *) usage; exit 0;;

    esac;
  done;

  clone_repos
  exit 0
}

main "$@"
