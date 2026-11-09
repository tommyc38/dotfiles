# Folder-based work environments, shared by zsh and bash (must stay valid in both, incl. bash 3.2).
#
# Which environment a shell has loaded depends on where it is:
#   1. the longest directory in a workenv-dirs.txt that contains $PWD (e.g. ~/dev/tungsten/printix -> printix).
#      Two mapping files are read: vault-key/workenv-dirs.txt (synced) and the machine-local
#      ~/.config/dotfiles/workenv-dirs.txt (this computer only; wins a tie).
#   2. otherwise the default named in ~/.workrc                (set with `workenv <name>`)
#
# Loading an env does two things:
#   - sources vault-key/**/<name>.env (tokens, API keys), after unsetting the previous env's exports;
#   - points npm/pnpm at a per-env user config built from layers (see _workenv_npmrc below).
#
# The rc files call _workenv_auto at startup and after every cd; it only affects the current shell.
# ~/.workrc changes only when you run `workenv <name>`, which also pins that shell to <name>
# (`workenv --auto` unpins it). State per shell: WORKENV_NAME, WORKENV_FILE, WORKENV_PINNED.

WORKENV_DIRS_FILE="${WORKENV_DIRS_FILE:-$DOTFILES/vault-key/workenv-dirs.txt}"
DOTFILES_LOCAL_DIR="${DOTFILES_LOCAL_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles}"
DOTFILES_NPMRC_CACHE="${DOTFILES_NPMRC_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/npmrc}"

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

# Env name for a directory (longest matching directory across both mapping files), or nothing.
_workenv_name_for_dir() {
  local here="$1/" map dir name best_dir="" best_name=""
  for map in "$WORKENV_DIRS_FILE" "$DOTFILES_LOCAL_DIR/workenv-dirs.txt"; do
    [ -f "$map" ] || continue
    while read -r dir name || [ -n "$dir" ]; do
      case "$dir" in ""|\#*) continue ;; esac
      dir="$(_workenv_expand "$dir")"
      dir="${dir%/}"
      case "$here" in
        # -ge: on an equal-length match the machine-local file (read second) wins.
        "$dir"/*) [ ${#dir} -ge ${#best_dir} ] && { best_dir="$dir"; best_name="$name"; } ;;
      esac
    done < "$map"
  done
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

# Point npm and pnpm at this env's user config, built from layers (later lines win):
#
#   1. machine  ~/.config/dotfiles/npmrc      this computer only, never synced — e.g. `registry=<mirror>`
#                                             on a Mac whose network blocks public npm
#   2. base     ~/.npmrc                      shared credentials (vault-key/npmrc)
#   3. org      vault-key/**/<name>.npmrc     next to <name>.env — the org's registry, scopes, extra auth
#
# A repo's own .npmrc still overrides all of these (npm and pnpm read it above the user config), so repos
# keep working the way they do for everyone else. The result is written to ~/.cache/dotfiles/npmrc/<name>
# (mode 600) and exported as npm_config_userconfig, which both npm and pnpm honour; COREPACK_NPM_REGISTRY
# follows the effective default registry so Corepack-provided pnpm comes from the same place.
# With no machine or org file, nothing is set and npm/pnpm use ~/.npmrc as usual.
_workenv_npmrc() {
  local env_file="$1" name="$2" machine org out registry=""
  machine="$DOTFILES_LOCAL_DIR/npmrc"
  org="${env_file%.env}.npmrc"
  [ -f "$machine" ] || machine=""
  [ -n "$env_file" ] && [ -f "$org" ] || org=""

  if [ -z "$machine" ] && [ -z "$org" ]; then
    unset npm_config_userconfig
    [ -n "${DOTFILES_COREPACK_SET:-}" ] && unset COREPACK_NPM_REGISTRY DOTFILES_COREPACK_SET
    return 0
  fi

  out="$DOTFILES_NPMRC_CACHE/${name:-default}"
  (umask 077; mkdir -p "$DOTFILES_NPMRC_CACHE"
   {
     [ -n "$machine" ] && { echo "; --- machine: $machine"; cat "$machine"; echo; }
     [ -f "$HOME/.npmrc" ] && { echo "; --- base: ~/.npmrc"; cat "$HOME/.npmrc"; echo; }
     [ -n "$org" ] && { echo "; --- org: $org"; cat "$org"; echo; }
   } > "$out")
  export npm_config_userconfig="$out"

  # Effective default registry = the last `registry=` line (later layers win).
  registry="$(sed -n 's/^[[:space:]]*registry[[:space:]]*=[[:space:]]*//p' "$out" | tail -1)"
  if [ -n "$registry" ]; then
    export COREPACK_NPM_REGISTRY="${registry%/}" DOTFILES_COREPACK_SET=1
  elif [ -n "${DOTFILES_COREPACK_SET:-}" ]; then
    unset COREPACK_NPM_REGISTRY DOTFILES_COREPACK_SET
  fi
}

# Load the environment this directory calls for (no-op when it's already loaded or the shell is pinned).
_workenv_auto() {
  [ -n "${WORKENV_PINNED:-}" ] && return 0
  local name file previous="${WORKENV_NAME:-}"
  name="$(_workenv_name_for_dir "$PWD")"
  if [ -n "$name" ]; then
    [ "$name" = "$previous" ] && [ -n "${WORKENV_LOADED:-}" ] && return 0
    file="$(_workenv_file_for_name "$name")"
  else
    file="$(_workenv_default_file)"
    [ -n "$file" ] && [ "$file" = "${WORKENV_FILE:-}" ] && [ -n "${WORKENV_LOADED:-}" ] && return 0
    name="$(basename "${file:-none}" .env)"
  fi
  [ -n "$file" ] && [ -f "$file" ] || { _workenv_npmrc "" ""; return 0; }

  _workenv_unload "${WORKENV_FILE:-}"
  # shellcheck disable=SC1090
  . "$file"
  export WORKENV_NAME="$name" WORKENV_FILE="$file"
  # Not exported: each new shell rebuilds its npm config once, so edits to the layer files apply to new shells.
  WORKENV_LOADED=1
  _workenv_npmrc "$file" "$name"

  # Say so when an interactive shell switches (not on the initial load at startup).
  if [ -n "$previous" ] && [ "$previous" != "$name" ]; then
    case "$-" in *i*) printf 'workenv: %s → %s\n' "$previous" "$name" >&2 ;; esac
  fi
}
