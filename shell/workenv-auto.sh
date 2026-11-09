# Folder-based work environments, shared by zsh and bash (must stay valid in both, incl. bash 3.2).
#
# Which environment a shell has loaded depends on where it is:
#   1. the longest directory in vault-key/workenv-dirs.txt containing $PWD   (e.g. ~/dev/printix -> printix)
#   2. otherwise the default named in ~/.workrc                              (set with `workenv <name>`)
#
# The rc files call _workenv_auto at startup and after every cd. Switching unsets the previous env's
# exported variables before loading the next, and only affects the current shell — ~/.workrc changes
# only when you run `workenv <name>` yourself, which also pins that shell to <name> (`workenv --auto`
# unpins it). State per shell: WORKENV_NAME (loaded env), WORKENV_FILE (its file), WORKENV_PINNED.

WORKENV_DIRS_FILE="${WORKENV_DIRS_FILE:-$DOTFILES/vault-key/workenv-dirs.txt}"

# Expand a leading ~ or $HOME in a path from one of our config files.
_workenv_expand() {
  case "$1" in
    "~"*) printf '%s\n' "$HOME${1#\~}" ;;
    '$HOME'*) printf '%s\n' "$HOME${1#\$HOME}" ;;
    '$DOTFILES'*) printf '%s\n' "$DOTFILES${1#\$DOTFILES}" ;;
    *) printf '%s\n' "$1" ;;
  esac
}

# The env file ~/.workrc points at (the default environment).
_workenv_default_file() {
  local line file=""
  [ -f "$HOME/.workrc" ] || return 0
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      source\ *|.\ *) file="$(_workenv_expand "${line#* }")" ;;
    esac
  done < "$HOME/.workrc"
  printf '%s\n' "$file"
}

# Env name for a directory from workenv-dirs.txt (longest matching directory), or nothing.
_workenv_name_for_dir() {
  local here="$1/" dir name best_dir="" best_name=""
  [ -f "$WORKENV_DIRS_FILE" ] || return 0
  while read -r dir name || [ -n "$dir" ]; do
    case "$dir" in ""|\#*) continue ;; esac
    dir="$(_workenv_expand "$dir")"
    dir="${dir%/}"
    case "$here" in
      "$dir"/*) [ ${#dir} -gt ${#best_dir} ] && { best_dir="$dir"; best_name="$name"; } ;;
    esac
  done < "$WORKENV_DIRS_FILE"
  printf '%s\n' "$best_name"
}

# Path of <name>.env anywhere in vault-key/ (excluding backups).
_workenv_file_for_name() {
  find "$DOTFILES/vault-key" -maxdepth 3 -path '*/vault_backups' -prune -o -type f -name "$1.env" -print 2>/dev/null | head -1
}

# Unset every variable an env file exports.
_workenv_unload() {
  local line var
  [ -n "$1" ] && [ -f "$1" ] || return 0
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      export\ *=*)
        var="${line#export }"
        var="${var%%=*}"
        [ -n "$var" ] && unset "$var"
        ;;
    esac
  done < "$1"
}

# Load the environment this directory calls for (no-op when it's already loaded or the shell is pinned).
_workenv_auto() {
  [ -n "${WORKENV_PINNED:-}" ] && return 0
  local name file previous="${WORKENV_NAME:-}"
  name="$(_workenv_name_for_dir "$PWD")"
  if [ -n "$name" ]; then
    [ "$name" = "$previous" ] && return 0
    file="$(_workenv_file_for_name "$name")"
  else
    file="$(_workenv_default_file)"
    [ -n "$file" ] && [ "$file" = "${WORKENV_FILE:-}" ] && return 0
    name="$(basename "${file:-none}" .env)"
  fi
  [ -n "$file" ] && [ -f "$file" ] || return 0

  _workenv_unload "${WORKENV_FILE:-}"
  # shellcheck disable=SC1090
  . "$file"
  export WORKENV_NAME="$name" WORKENV_FILE="$file"

  # Say so when an interactive shell switches (not on the initial load at startup).
  if [ -n "$previous" ] && [ "$previous" != "$name" ]; then
    case "$-" in *i*) printf 'workenv: %s → %s\n' "$previous" "$name" >&2 ;; esac
  fi
}
