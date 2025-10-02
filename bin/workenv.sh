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
# Remove the variables exported from the current env file.
function remove_current_env() {
   local line
   local variable_name=""
   local current_env_file=""
   current_env_file="$(get_current_env_file)"
   if [ -n "$current_env_file" ]; then
     while IFS= read -r line; do
       if [[ $line == export* ]]; then
         variable_name=${line#export }
         variable_name=${variable_name%%=*}
         if [ -n "$variable_name" ]; then
           unset "$variable_name"
         fi
       fi
     done < "$current_env_file"
   fi
}

# Get the current env file.
function get_current_env_file() {
  local line
  local current_env_file
  local workrc="$HOME/.workrc"
    if [ -e "$workrc" ]; then
      while IFS= read -r line; do
        if [[ $line == source* ]]; then
          current_env_file=${line#source }
          current_env_file=${current_env_file//'$HOME'/$HOME}
          current_env_file=${current_env_file//'~'/$HOME}
          current_env_file=${current_env_file//'$DOTFILES'/$DOTFILES}
          if [ -e "$current_env_file" ]; then
            echo "$current_env_file"
          fi
        fi
      done < "$workrc"
    fi
}

# Update the .workrc file with the new env file and load it into the environment.
function update_and_load_workrc () {
  local env="$1"
  local new_env_file=""
  local workrc="$HOME/.workrc"
  
  # Resolve symlinks - works on both macOS and Linux
  if [ -L "$workrc" ]; then
    # It's a symlink, follow it
    if [ "$(uname)" = "Darwin" ]; then
      # macOS readlink doesn't support -f by default
      workrc="$(readlink "$workrc")"
      # If readlink result is relative, make it absolute
      if [[ "$workrc" != /* ]]; then
        workrc="$HOME/$workrc"
      fi
    else
      # Linux has -f flag
      workrc="$(readlink -f "$workrc")"
    fi
  fi
  
  if [ -e "$workrc" ]; then
    new_env_file="$(find_env_file "$env")"
    if [ -e "$new_env_file" ]; then
      local pattern="^source"
      local new_line="source $new_env_file"
      
      # macOS sed requires empty string after -i for in-place edit
      # Use @ as delimiter since paths contain slashes
      if [ "$(uname)" = "Darwin" ]; then
        sed -i '' "s@$pattern.*@$new_line@" "$workrc"
      else
        sed -i "s@$pattern.*@$new_line@" "$workrc"
      fi
      
      source "$workrc"
      echo "Now using environment: $env"
    else
      echo "Couldn't find environment: $env"
      echo "Use 'workenv --list' to see available environments"
    fi
  else
    echo "No ~/.workrc file found!"
  fi
}

# Find the .env file that matches the env name.
function find_env_file() {
    local base_name=$1
    local root_dir="$DOTFILES/vault-key"
    local file=""
    local env_file=""
    if [ -e "$root_dir" ]; then
      while IFS= read -r -d '' file; do
        local filename=""
        filename=$(basename "$file")
        if [[ $filename == "$base_name.env" ]]; then
            env_file="$file"
            break
        fi
      done < <(find "$root_dir" -type d -name "vault_backups" -prune -o -type f -name '*.env' -print0)
      if [ -n "$env_file" ]; then
        echo "$env_file"
      fi
    fi
}

# List all available environment files in vault-key directory.
function list_environments() {
    local root_dir="$DOTFILES/vault-key"
    local file=""
    local env_name=""
    local found_any=false
    
    if [ ! -d "$root_dir" ]; then
        echo "Environment directory not found: $root_dir"
        return 1
    fi
    
    echo "Available environments:"
    echo ""
    
    while IFS= read -r -d '' file; do
        found_any=true
        env_name=$(basename "$file")
        env_name="${env_name%.env}"
        # Show relative path from home directory for cleaner output
        local display_path="${file/#$HOME/~}"
        printf "  %-20s %s\n" "$env_name" "$display_path"
    done < <(find "$root_dir" -type d -name "vault_backups" -prune -o -type f -name '*.env' -print0 | sort -z)
    
    if [ "$found_any" = false ]; then
        echo "  No environment files found in $root_dir"
        echo ""
        echo "Environment files should be named: <name>.env"
        return 1
    fi
    
    echo ""
    echo "Usage: workenv <environment-name>"
}

# Show the script usage.
function usage() {
echo "
Usage:
  . $script [-h|--help] [-e|--env] [-l|--list] [environment]

Description:
  If you work on multiple projects, you often need to load global project variables (e.g. NPM_REGISTRY, NPM_TOKEN,
  etc.). This script simplifies the process of switching between project environments. Because scripts are ran in a
  child process, you can't run this script without a \".\" before calling the script (e.g. . $script [options] args).
  It's recommended that you use a shell function (e.g. .bashrc, .zshrc, etc.) as a wrapper to make it easier. Moreover,
  this script also assumes you source a ~/.workrc file from within your shell configuration (e.g. .bashrc, zshrc) to
  load your project environment. See example for more details.

Args:
  environment   The name of the environment file without the .env extension.

Options:
  -h, --help    Show this help message and exit.
  -e, --env     Show the currently loaded environment name.
  -l, --list    List all available environments in \$DOTFILES/vault-key directory.

Example Files:
  ~/dotfiles/vault-key/org_one/org_one.env:
    export NPM_REGISTRY='registry'
    export NPM_TOKEN='token'

  ~/dotfiles/vault-key/org_two/org_two.env:
    export NPM_REGISTRY='org_two_registry'
    export NPM_TOKEN='org_two_token'

  ~/some/path/org/org.env:
    export NPM_REGISTRY='org_registry'
    export NPM_TOKEN='org_token'

  ~/.zshrc OR ~/.bashrc:
    source ~/.workrc
    workenv() {
      . $script \"\$@\"
    }

  ~/.workrc:
    source ~/dotfiles/env/org_one.env

Example Usage:
  workenv --list                            # List all available environments.
  workenv org_two                           # Switch to org_two environment.
  workenv --env                             # Show current environment name.
  workenv --help                            # Show the help menu.

  ** The .workrc file must contain only one source command but can have commented lines (e.g. # comment).  Moreover,
  this file must be in the home directory and the source command will be updated to the new environment_name.env file
  when switching environments. Lastly, you can use the following wildcards when defining the sourced file path: ~,
  \$DOTFILES, \$HOME."
}

# Update the shell environment with a new work env file.
function main() {
  local env_option=""
  local help_option=""
  local list_option=""
  local env=""
  local current_env_file=""
  local current_env=""
  local short="hel"
  local long="help,env,list"
  local options

  if [ "$(uname)" = "Darwin" ]; then
    # Detect Homebrew prefix for both Intel and Apple Silicon
    if [[ -x "/opt/homebrew/bin/brew" ]]; then
      HOMEBREW_PREFIX="/opt/homebrew"
    elif [[ -x "/usr/local/bin/brew" ]]; then
      HOMEBREW_PREFIX="/usr/local"
    fi
    
    if [ -e "$HOMEBREW_PREFIX/opt/gnu-getopt/bin/getopt" ]; then
      options=$("$HOMEBREW_PREFIX/opt/gnu-getopt/bin/getopt" -l "$long" -o "$short" -a -- "$@")
    else
      echo "This script requires the latest getopt command. Upgrade with: brew install gnu-getopt"
    fi
  else
      options=$(getopt -l "$long" -o "$short" -a -- "$@")
  fi

  # Set the positional parameters to the parsed getopt command output.
  eval set -- "$options"

  while true; do
    case "$1" in
      -e|--env) env_option="true"; shift;;
      -h|--help) help_option="true"; shift;;
      -l|--list) list_option="true"; shift;;
      --) shift;;
      *)
        env="$1"
        break
    esac
  done

  current_env_file="$(get_current_env_file)"
  if [ -e "$current_env_file" ]; then
    current_env="$(basename "$current_env_file")"
    current_env="${current_env%.env}"
  fi

  if [ -n "$help_option" ]; then
    usage
  elif [ -n "$list_option" ]; then
    list_environments
  elif [ -n "$env_option" ]; then
    if [ -e "$current_env_file" ]; then
      echo "$current_env"
    else
      echo "Please ensure you have a ~/.workrc and the source command points to an existing .env file! See --help."
    fi
  elif [ -z "$env" ]; then
    echo "No environment defined! Use 'workenv --list' to see available environments."
  else
    if [ "$env" = "$current_env" ]; then
      echo "Already using $env"
    else
      remove_current_env
      update_and_load_workrc "$env"
    fi
  fi
}

main "$@"

