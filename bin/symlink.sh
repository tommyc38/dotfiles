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

# Directories
symlink_destination_dir=$HOME          # Root directory for all symlinks targets without the --file.
backup_directory=$symlink_destination_dir/dotfiles_backup  # Directory to back up files matching symlink targets.

# All sources are defined in the set_dotfiles_root_dir function because they depend on the dotfiles_directory path.

# The file option
source_target_file=
has_updated_sources=

# Dry run option
dry_run=""

# Messages
message_indent="  "
symlinks_created_msg=
symlinks_skipped_msg=
symlinks_failed_msg=
symlinks_duplicated_msg=
backups_created_msg=
restored_success_msg=
restored_failed_msg=
restored_removed_msg=
clear='\033[0m' # Terminal output color terminator.

# Set the dotfiles root directory.
function set_dotfiles_root_dir() {
  local script_path
  local git_top_level_path
  dotfiles_directory=  # Root dotfiles directory.

  script_path="$(dirname -- "$( readlink -f -- "$0")")"
  git_top_level_path="$(git rev-parse --show-toplevel 2>/dev/null)"

  # Assume the dotfiles are always in a repo for backup and use the repo root path.
  if [ -n "$git_top_level_path" ]; then
   dotfiles_directory="$git_top_level_path"

  # Check the script directory.
  elif [ "$(basename "$script_path")" == "dotfiles" ]; then
   dotfiles_directory="$script_path"

  # Check the script directory's parent directory.
  elif [ "$(basename "${script_path%/*}")" == "dotfiles" ]; then
   dotfiles_directory="${script_path%/*}"
  else
   echo "The dotfiles directory couldn't be established! See the script's set_dotfiles_root_dir function."
   exit 1
  fi

  if [ ! -d "$dotfiles_directory" ]; then
   echo "The dotfiles directory doesn't exist!"
   exit 1
  fi

}

# Creates a backup directory.
function create_backup_directory() {
  if [ ! -e "$backup_directory" ]; then
    [ -z "$dry_run" ] && mkdir -p "$backup_directory"
  fi
}

# Symlink a file.
function symlink_file() {
  local source_file=$1 # The source dotfile path of a symlink.
  local target_file=$2 # The destination file path of a symlink.
  local target_file_parent_dir="${target_file%/*}"
  local message

  local source_file_name
  source_file_name="$(get_message_file_name "$source_file")"

  # Some of our targets may need directories created.
  if [ ! -e "$target_file_parent_dir" ]; then
    [ -z "$dry_run" ] && mkdir -p "$target_file_parent_dir"
  fi
  message="$message_indent$source_file_name|-->|$target_file\n"
  symlinks_created_msg=$symlinks_created_msg$message
  [ -z "$dry_run" ] && ln -s "$source_file" "$target_file"
}

# Backup or skip an existing file found that matches a dotfile to be symlinked.
function backup_file() {
  local target_file="$1" # The target path of a symlink.
  local backup_file
  local message
  backup_file="$backup_directory/$(basename "$target_file")"

  local backup_file_name
  backup_file_name="$(get_message_file_name "$target_file")"

  # Check if there is already a backup file matching a file that needs to be backed up.
  if [ -e "$backup_file" ]; then
    false
    return
  # Check if the original file is a symlink.
  elif [ -L "$target_file" ]; then
    message="$message_indent$backup_file_name (symlinked from source: $(readlink -f "$target_file"))\n"
    backups_created_msg=$backups_created_msg$message
    if [ -z "$dry_run" ]; then
      ln -s "$(readlink -f "$target_file")" "$backup_file" &> /dev/null
      rm -r "$target_file"
    fi
    true
    return
  # Move the original file to the backup directory.
  else
    message="$message_indent$backup_file_name|-->|$backup_file\n"
    backups_created_msg=$backups_created_msg$message
    create_backup_directory
    [ -z "$dry_run" ] && mv "$target_file" "$backup_file"
    true
    return
  fi
}

# Get the proper file name message for the output.
function get_message_file_name() {
  local file="$1"

  if [ -n "$source_target_file" ]; then
    echo "$file"
    echo
  else
    echo "$(basename "$file")"
echo
  fi
}

# Restore a file from the backup directory
function restore_file() {
  local source_file="$1"
  local target_file="$2"
  local backup_file
  local message
  backup_file="$backup_directory/$(basename "$target_file")"

  if [ -n "$source_target_file" ];then
    symlink_destination_dir="${target_file%/*}"
  fi

  local backup_file_name
  backup_file_name="$(get_message_file_name "$backup_file")"

  if [ -e "$backup_file" ]; then
    # Show correct messages on a dry run.
    if [ -n "$dry_run" ]; then
      # Check if the target destination has a matching file (excluding our own symlinks).
      if [ -e "$target_file" ] && [ "$(readlink -f "$target_file")"  != "$source_file"  ]; then
        message="$message_indent$backup_file_name|-->|$(color_red "$target_file")\n"
        restored_failed_msg=$restored_failed_msg$message
      else
        message="$message_indent$backup_file_name|-->|$target_file\n"
        restored_success_msg=$restored_success_msg$message
      fi
    # Our own symlinks should be removed so if the target exits we can't restore our backup file.
    elif [ -e "$target_file" ]; then
      message="$message_indent$backup_file_name|-->|$(color_red "$target_file")\n"
      restored_failed_msg=$restored_failed_msg$message

    # Restore the file.
    else
      message="$message_indent$backup_file_name|-->|$target_file\n"
      restored_success_msg=$restored_success_msg$message
      if [ -L "$backup_file" ]; then
        if [ -z "$dry_run" ];then
           ln -s "$( readlink -f "$backup_file")" "$target_file"
           rm "$backup_file"
           remove_empty_dirs "$target_file"
        fi
      else
        [ -z "$dry_run" ] && mv "$backup_file" "$target_file"
        remove_empty_dirs "$target_file"
      fi
    fi
  fi
}

# Iterates over the dotfiles and removes the symlinks created and restores any original files found.
function restore() {
  local message
  local target_file

  for source_file in "${files_to_symlink[@]}"; do
    if [ -n "$source_target_file" ]; then
      target_file="$(get_target_from_file "$source_target_file" "$source_file")"
    else
      target_file="$(get_target "$source_file")"
    fi

    if [ "$?" != "0" ]; then
      echo "$(color_red "Couldn't establish a target for $source_file")"
      echo "$(color_red "Check your source is correct and/or update the target in the get_target function.")"
      exit 1
    fi
    if [ "$(readlink -f "$target_file")"  == "$source_file" ]; then
      # Remove dotfile symlinks.
      local source_file_name
      source_file_name="$(get_message_file_name "$source_file_name")"
      message="$message_indent$source_file_name|-->|$target_file\n"
      restored_removed_msg=$restored_removed_msg$message
      [ -z "$dry_run" ] && rm "$target_file"
    fi
    if [ -e "$backup_directory" ]; then
      restore_file "$source_file" "$target_file"
    fi
  done

}

# Returns the symlink target based on the source file.
function get_target(){
  local source="$1"
  local target
  local vim_directory=$symlink_destination_dir/.vim
  local neovim_directory=$symlink_destination_dir/.config/nvim
  local plugins_directory=$vim_directory/plugged/custom-plugins

  if [ "$(basename "$source")" == "darcula" ]; then
      target="$plugins_directory/darcula"

  elif [ "$(basename "$source")" == "init.vim" ];then
      target="$neovim_directory/init.vim"

  elif [ "$(basename "$source")" == "coc-settings.json" ];then
      target="$neovim_directory/coc-settings.json"

  elif [ "$(basename "$source")" == "plugins.vim" ];then
      target="$vim_directory/plugins.vim"

  elif [ "$(basename "$source")" == "karabiner.json" ]; then
      target="$symlink_destination_dir/.config/karabiner/$(basename "$source")"

  elif [ "$(basename "$source")" == ".vimrc" ]; then
      target="$symlink_destination_dir/.vimrc"

  elif [[ "$source" == *.symlink ]]; then
      target="$symlink_destination_dir/.$(basename "$source" ".symlink")"

  else
      exit 1
  fi

  echo "$target"

}
# Get the target from a given source in the supplied file.  Note, the first invocation builds the list of sources
# and sets them to the global variable $files_to_symlink that other functions depend on.
get_target_from_file(){
  local symlink_source_target_file="$1"
  local search="$2"
  local source
  local target
  local duplicate_targets=()
  local sed_pattern='/^\s*#/d;/^\s*$/d' # Delete blank or commented lines.
  files_to_symlink=()

  # Loop through file line by line
  while IFS=" | " read -r source target; do

    if [ -z "$source" ] || [ -z "$target" ]; then
      echo "A source or target could not be parsed.  Please check ${source_target_file}"
      exit 1
    fi

    # Substitute the $HOME/DOTFILES string for the $HOME/DOTFILES variable.
    # Note, if the $DOTFILES variable isn't set in the env that it will use the $dotfiles_directory as the default.
    source="${source//'$HOME'/$HOME}"
    target="${target//'$HOME'/$HOME}"
    source="${source//'~'/$HOME}"
    target="${target//'~'/$HOME}"
    local dot_path="${DOTFILES:-$dotfiles_directory}"
    source="${source//'$DOTFILES'/$dot_path}"
    target="${target//'$DOTFILES'/$dot_path}"

    # If we know the source is a regular file and the target is a directory
    # we update the target to be more specific so the script doesn't try to back up the directory if it exists.
    if [ -f "$source" ] && [ -d "$target" ]; then
      target="$target/${source##*/}"
    fi

    # $files_to_symlink is a global variable, so we only want to add items on the first invocation of this function.
    if [ -z "$has_updated_sources" ]; then
      files_to_symlink+=("$source")
      for target_duplicate in "${duplicate_targets[@]}"; do
        if [ "$target" == "$target_duplicate" ]; then
         echo "Duplicate targets in file!"
         echo "  $target"
         exit 1
        fi
      done
      duplicate_targets+=("$target")
    fi

    if [ "$search" == "$source" ]; then
      echo "$target"
      return
    fi

  done < <(sed "$sed_pattern" "$symlink_source_target_file")
  has_updated_sources=true
}

# Iterate over the dotfiles to symlink.
function symlink_dotfiles(){
  local skip="$1" # Truthy string to enable skip
  local target_file
  local message

  for source_file in "${files_to_symlink[@]}"; do

    if [ -n "$source_target_file" ]; then
      target_file="$(get_target_from_file "$source_target_file" "$source_file")"
    else
      target_file="$(get_target "$source_file")"
    fi

    if [ "$?" != "0" ]; then
      echo "$(color_red "Couldn't establish a target for $source_file")"
      echo "$(color_red "Check your source is correct and/or update the target in the get_target function.")"
      exit 1
    fi
    if [ -e "$target_file" ]; then
      local source_file_name
      source_file_name="$(get_message_file_name "$source_file_name")"

      if [ "$source_file" == "$(readlink -f "$target_file")" ]; then
        message="$message_indent$source_file_name|-->|$target_file\n"
        symlinks_duplicated_msg=$symlinks_duplicated_msg$message
      elif [ -n "$skip" ]; then
        message="$message_indent$source_file_name\n"
        symlinks_skipped_msg=$symlinks_skipped_msg$message
      else
        if backup_file "$target_file"; then
          symlink_file "$source_file" "$target_file"
        else
          message="$message_indent$(color_red "$source_file_name|-->|$target_file")\n"
          symlinks_failed_msg=$symlinks_failed_msg$message
        fi
      fi
    else
      symlink_file "$source_file" "$target_file"
    fi
  done
}

# Returns a string color coded to red output.
function color_red() {
  local message="$1"
  local color_red='\033[0;31m'
  echo -ne $color_red$message$clear
}

# Parses a message delimited with "|" to columns for better display.
function message_to_column() {
  local message="$1"
  echo -e "$( column -s "|" -t <<< "$(echo -en "$message")")"
}

# Run either "symlink" or "restore" mode. Pass a truthy string to skip matching files.
function run_type() {
  local type=$1 # Either "symlink" or "restore".
  local skip=$2 # Either the empty or truthy string.
  [ "$type" == "symlink" ] && echo -e "Sym-linking dotfiles...\n" || echo -e "Restoring original dotfiles...\n"
  if [ "$type" = "restore" ]; then
    restore
    [ -n "$restored_removed_msg" ] && echo -e "Removed Symlinks:\n$( message_to_column "$restored_removed_msg")\n"
    [ -n "$restored_success_msg" ] && echo -e "Restored Files:\n$( message_to_column "$restored_success_msg")\n"
    [ -n "$restored_failed_msg" ] && echo -e "Restored Failed - Target already exists:\n$(message_to_column "$restored_failed_msg")\n"

    if [ -z "$dry_run" ]; then
      # Check if the backup directory is empty.
      if [ -e "$backup_directory" ]; then
        if [ -z "$(ls -A "$backup_directory")" ]; then
          echo "Backup directory empty and removed: $backup_directory"
          [ -z "$dry_run" ] && rm -r "$backup_directory"
        else
         echo "Backup directory wasn't removed because it wasn't empty."
         echo "Check the files in $backup_directory against those matching in $symlink_destination_dir before removing."
        fi
      else
        echo -e "Nothing to restore. No backup directory found: $backup_directory\n"
        echo -e "If you have a custom backup directory add the --backup-directory option. See usage: $0 --help"
      fi
    fi
  fi

  if [ "$type" = "symlink" ]; then
    if [ -n "$skip" ]; then
      symlink_dotfiles "skip"
    else
      symlink_dotfiles
    fi
    [ -n "$symlinks_created_msg" ] && echo -e "Symlinks Created:\n$(message_to_column "$symlinks_created_msg")\n"
    [ -n "$symlinks_skipped_msg" ] && echo -e "Symlinks Skipped:\n$(message_to_column "$symlinks_skipped_msg")\n"
    [ -n "$symlinks_duplicated_msg" ] && echo -e "Symlinks Already Exist:\n$(message_to_column "$symlinks_duplicated_msg")\n"
    [ -n "$symlinks_failed_msg" ] && echo -e "Symlinks Failed - Original file can't be backed up, it already exists in backup directory:\n$(message_to_column "$symlinks_failed_msg")\n"
    [ -n "$backups_created_msg" ] && echo -e "Original Files/Directories Backed Up:\n$(message_to_column "$backups_created_msg")\n"
  fi

  [ -n "$dry_run" ] && echo "Dry Run"
  echo "Done."
}

# View how to use the script.
function usage() {
  echo "
Usage:
  $0 [-h|--help] [-d|--dry-run] [-s|--skip] [-b|--backup-directory <backup-directory>] [-f|--file <directory>]
  [-v|--include-vim] [-k|--include-karabiner] [-R|--restore]

Description:
  Symlink configuration files in the dotfiles directory to their respective target directories. Dotfiles with a .symlink
  extension will be symlinked to the \$HOME directory. If a symlink target already exists then that file will be moved
  to the backup directory (\$HOME/dotfiles_backup). If an existing target is a symlink, those links will be preserved
  and restored. You can also include the [-s|--skip] option to skip any targets that already exist instead of moving
  them to the backup directory. If you need more flexibility, you can use a custom file with source and targets defined
  to symlink, see the example below.

Options:
  -d, --dry-run                  Log the actions without executing any file operations.
  -b, --backup-directory <dir>   A custom backup directory to store existing targets. The default is \$HOME/dotfiles_backup.
  -s, --skip                     Skip sym-linking to targets that already exist. The default behavior is to move existing
                                 targets to the backup directory.
  -R, --restore                  Restore files from the backup directory and remove dotfile symlinks. If you symlinked
                                 files using the [-f|--file <file>] option then that option and corresponding file
                                 are required to perform a restore.
  -v, --include-vim              Include sym-linking vim files.
  -f, --file <file>              A file containing the source and target paths for symlinks. See example.
  -k, --include-karabiner        Include sym-linking karabiner.json.
  -h, --help                     Get help on running this script.

Examples:
  $0                                               # Symlink all files with a .symlink extension to \$HOME.
  $0 --include-vim --include-karabiner             # Symlink all files.
  $0 --backup-directory dot-backups                # Using a custom backup directory. Relative or absolute paths.
  $0 --dry-run --include-vim --include-karabiner   # See which files will be affected before running file operations.
  $0 --restore                                     # Restore all files from the default backup directory.

  When you include the [-f|--file <file>] option, the paths in the file must be delimited by \" | \".  For example,
  let's assume we are using the command, '$0 --file symlink.txt', and the contents of symlink.txt are:

 \$HOME/some/path/file.txt | \$HOME/another/path
  ~/some/path/file-two.txt | ~/another/path/another-file.txt
  ~/some/path/directory | ~/another/path/directory
  # This is a comment and won't be read.

  $0 --file symlink.txt  --backup-directory dot-backups           # Symlink all sources to targets in symlink.txt
  $0 --restore --backup-directory dot-backups --file symlink.txt  # Restoring from the backup directory. --file is required.

  ** Files can contain comments with any line starting with '#'.

  ** \$HOME, ~, and \$DOTFILES are the only valid wildcards in the source/target file. You also don't need to
    export \$DOTFILES since this is just a wildcard the script resolves on its own and not an environment variable."
}

# Parse the options passed to the script.
function main() {
  local short="dsvkRb:f:"
  local long="dry-run,skip,include-vim,include-karabiner,restore,file:,backup-directory:"
  local options
  local include_vim
  local include_karabiner
  local skip
  local type="symlink"

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

  # Set the default dotfile root path.
  set_dotfiles_root_dir

  # Set the positional parameters to the parsed getopt command output.
  eval set -- "$options"

  while true; do
    case "$1" in
      -d|--dry-run|-dry-run) dry_run="true"; shift;;
      -b|--backup-directory|-backup-directory) shift;
        backup_directory="$(readlink -f "$1")"
        shift ;;
      -s|--skip|-skip) skip="true"; shift;;
      -R|--restore|-restore) type="restore"; shift;;
      -f|--file|-file) shift
        source_target_file="$(readlink -f "$1")"
        if [ ! -e "$source_target_file" ];then
          echo "The symlink file you supplied could not be found! See usage: vault --help"
          echo "  $source_target_file"
          echo "  $1"
          exit 1
        fi
        shift;;
      -v|--vim|-vim) include_vim="true"; shift;;
      -k|--karabiner|-karabiner) include_karabiner="true"; shift;;
      -h|--help|-help) usage; exit 0;;
      --) break;;
      *) usage; exit 0;;

    esac;
  done;

  # Set the source files from a source_file.txt
  if [ "$source_target_file" ]; then
    # The first invocation builds the array from the file.
    get_target_from_file "$source_target_file"
  else
    # Files with a .symlink extension.
    local dot_symlink_ext_sources=()
    while IFS=  read -r -d $'\0'; do
       dot_symlink_ext_sources+=("$REPLY")
    done < <(find -H "$dotfiles_directory" -maxdepth 3 -name "*.symlink" -print0)

    local vim_sources=("$dotfiles_directory/vim/custom-plugins/darcula" "$dotfiles_directory/vim/init.vim"
    "$dotfiles_directory/vim/coc-settings.json" "$dotfiles_directory/vim/plugins.vim" "$dotfiles_directory/vim/.vimrc")

    local karabiner_sources=("$dotfiles_directory/karabiner/karabiner.json")

    files_to_symlink=("${dot_symlink_ext_sources[@]}") # Default files to symlink.

    if [ "$type" == "symlink" ]; then
      [ -n "$include_vim" ] && [ -z "$include_karabiner" ] && files_to_symlink=("${dot_symlink_ext_sources[@]}" "${vim_sources[@]}")
      [ -z "$include_vim" ] && [ -n "$include_karabiner" ] && files_to_symlink=("${dot_symlink_ext_sources[@]}" "${karabiner_sources[@]}")
      [ -n "$include_vim" ] && [ -n "$include_karabiner" ] && files_to_symlink=("${dot_symlink_ext_sources[@]}" "${karabiner_sources[@]}" "${vim_sources[@]}")
      [ -z "$include_vim" ] && [ -z "$include_karabiner" ] && files_to_symlink=("${dot_symlink_ext_sources[@]}")

    # Restore targets are built off of sources, so we need to include all sources here.
    else
      files_to_symlink=("${dot_symlink_ext_sources[@]}" "${karabiner_sources[@]}" "${vim_sources[@]}")
    fi
  fi

  if [ "${#files_to_symlink[@]}" == "0" ]; then
    echo "No source files!"
    exit 1
  fi

  for source_file in "${files_to_symlink[@]}"; do
    if [ -z "$source_file" ]; then
      echo "Source not found!"
      exit 1
    fi
  done

  run_type "$type" "$skip"
  exit 0
}

main "$@"
