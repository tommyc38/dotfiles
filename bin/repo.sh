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

dry_run=
default_directory=
source_file=
npm_install=

# We need to have access to nvm
export NVM_DIR=$HOME/.nvm;
source $NVM_DIR/nvm.sh;

# Install javascript packages.
function npm_install() {
  local directory="$1"
  local lockfile_version
  local node_version
  if [ -n "$npm_install" ] && [ -e "$directory" ] && [ -n "$(node --version)" ] && [ -n "$( ls "$directory/package-lock.json" 2>/dev/null)" ]; then
    if [ -n "$(ls "$directory/node_modules" 2>/dev/null)" ]; then
      echo "NPM packages already installed. Skipping!"
    else
      echo "Installing npm packages from ..${directory//$HOME/}/package.json"
      lockfile_version="$(node -pe "require(\"$directory/package-lock.json\").lockfileVersion" )"
      node_version=$(node --version | cut -d "." -f 1 | sed 's/v//')
      if [ "$lockfile_version" -eq 1 ]; then
        if [ "$node_version" -gt 14 ]; then
          echo "Switching to node v14 for compatibility with lockfile version 1"
          [ -z "$dry_run" ] && nvm use 14
        fi
      elif [ "$lockfile_version" -eq 2 ]; then
        if [ "$node_version" -lt 15 ] || [ "$node_version" -gt 18 ]; then
          echo "Switching to node v16 for compatibility with lockfile version 2"
          [ -z "$dry_run" ] && nvm use 16
        fi
      else
        if [ "$node_version" -lt 19 ]; then
          echo "Switching to node v19 for compatibility with lockfile version 3"
          [ -z "$dry_run" ] && nvm use 19
        fi
      fi
      if [ -z "$dry_run" ]; then
         cd "$directory" 1>/dev/null || return;
         npm install
         cd - 1>/dev/null || return
      fi
    fi
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
    fi

    repo_name="$(basename "$repo" | sed 's/\.git$//')"
    directory=${directory//'$HOME'/$HOME}
    directory=${directory//'~'/$HOME}
    directory=${directory:-$default_directory}

    if [ -e "$directory" ] && [ "$directory" != "$directory/$repo_name" ] && [ -z "$(ls -A "$directory/.git" 2>/dev/null)" ]; then
      install_dir="$directory/$repo_name"
    else
      install_dir="$directory"
    fi

    if [ -z "$directory" ]; then
      echo "No destination directory supplied ($count/$line_count). Clone skipped! -- $repo"
    elif [ -e "$install_dir" ] && [ -n "$(ls -A "$install_dir")" ]; then
      echo "Destination ~${install_dir//$HOME/} already exists ($count/$line_count). Clone skipped! -- $repo"
      npm_install "$install_dir"
    else
      echo "Cloning ($count/$line_count) - $repo ~${install_dir//$HOME/}"
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
  $0 [-h|--help] [-d|--dry-run] [-i|--npm-install] [-D|--default-directory <directory>] [-f|--file <filename>]
Description:
  Clone multiple git repositories and, optionally, install their dependencies using npm.  You must have nvm and
  node versions 14, 16, and 19 installed.  After cloning a repository, the lockfileVersion property in package-lock.json
  is used to choose the respective node (and npm) version to install the packages with.

Options:
  -h, --help                      Show this help message and exit.
  -d, --dry-run                   Show what would be done without actually doing it.
  -i, --npm-install               Install npm packages for each cloned repository.
  -D, --default-directory <dir>   Specify a default directory to clone repositories into (if not specified in the source file).
  -f, --file <file>               A file which has all the repository urls and optional install directories.

Example:
  source_file.txt:
  git@github/org/org-repo.git \$HOME/dev/work
  git@bitbucket.org/org/org-repo-two.git \$HOME/dev/work/org-two-bitbucket
  git@github/org/org-repo-three.git
  # This line is a comment.  Inline comments aren't supported.

  $0 -file source_file.txt -D \$HOME/dev/work

  first repo will be cloned to \$HOME/dev/work/org-repo
  second repo will be cloned to \$HOME/dev/work/org-two-bitbucket
  third repo will be cloned to \$HOME/dev/work/org-repo-three"
}

# Parse the options passed to the script.
function main() {
  local short="dhif:D:"
  local long="dry-run,npm-install,npm-install,help,default-directory:,file:"
  local options

  if [ "$(uname)" == "Darwin" ]; then
    if [ -e "/usr/local/opt/gnu-getopt/bin/getopt" ]; then
      options=$(/usr/local/opt/gnu-getopt/bin/getopt -l "$long" -o "$short" -a -- "$@")
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
      -D|--default-directory|-defualt-directory) shift
        default_directory="$(readlink -f "$1")"
        if [ ! -e "$default_directory" ];then
          echo "You must supply a default directory. See --help."
          echo "  $default_directory"
          exit 1
        fi
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
