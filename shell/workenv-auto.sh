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
#   - points npm/pnpm at that env's own user config, <name>.npmrc + a default registry for this network
#     (see "npm / pnpm" below).
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

# --- npm / pnpm ------------------------------------------------------------------------------------
#
# Each env's npm/pnpm config is ONE file, vault-key/**/<name>.npmrc next to <name>.env: its scopes and
# every credential it needs, written as ${VAR} (the values live only in <name>.env). It's copied to
# ~/.cache/dotfiles/npmrc/<name> (mode 600) with a default `registry=` picked for the current network,
# and exported as npm_config_userconfig, which npm and pnpm both use INSTEAD of ~/.npmrc.
#
# Why this works with any repo, without changing it (verified with npm 11 / pnpm 11):
#   - a repo's own .npmrc sits ABOVE the user config and is merged key by key, so a repo that sets
#     `registry=` or `@scope:registry=` still gets the token for that host from here;
#   - pnpm ignores ${VAR} credentials in a repo .npmrc for scoped registries, but expands them here;
#   - only npm_config_userconfig (a file path) and COREPACK_NPM_REGISTRY (where Corepack downloads pnpm
#     itself) are exported. Never export npm_config_registry & co: environment settings would override
#     the repo's own .npmrc.
# One repo-side rule remains: every ${VAR} a repo's .npmrc references must be exported by its folder's
# env, or npm/pnpm send the literal "${VAR}" (401). `workenv --doctor` checks that across all repos.
#
# Default registry, first match wins:
#   1. WORKENV_REGISTRY        this shell only: `workenv --registry public|mirror|<url>` (auto = clear)
#   2. DOTFILES_NPM_REGISTRY   this machine: set in ~/.config/dotfiles/local.sh (same values)
#   3. a `registry=` line in <name>.npmrc (fixed, never probed)
#   4. the first reachable URL on its `; @registry-candidates <url> <url> ...` line, probed with
#      <url>/-/ping (2s) and cached for $DOTFILES_REACH_TTL_MIN minutes (`workenv --refresh` re-probes)
#   5. none: npm's built-in default (public npm)
DOTFILES_REACH_CACHE="${DOTFILES_REACH_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/npm-reach}"
DOTFILES_REACH_TTL_MIN="${DOTFILES_REACH_TTL_MIN:-15}"
DOTFILES_NPM_PUBLIC="https://registry.npmjs.org/"

# Does this registry answer from the current network? (cached)
_workenv_reachable() {
  local url="${1%/}/" f code rc
  f="$DOTFILES_REACH_CACHE/$(printf '%s' "$url" | tr -c 'A-Za-z0-9' '_')"
  if [ -f "$f" ] && [ -n "$(find "$f" -mmin -"$DOTFILES_REACH_TTL_MIN" 2>/dev/null)" ]; then
    [ "$(cat "$f")" = ok ]
    return
  fi
  code="$(curl -s -o /dev/null -m 2 -w '%{http_code}' "${url}-/ping" 2>/dev/null)"
  rc=$?
  (umask 077; mkdir -p "$DOTFILES_REACH_CACHE")
  case "$rc:$code" in
    # Any HTTP answer below 500 means the host is there (404/401 are normal for -/ping on some
    # registries); TLS errors too — the server answered, curl just lacks a corporate CA.
    0:[1234]??|35:*|51:*|58:*|60:*) echo ok > "$f"; return 0 ;;
    *) echo fail > "$f"; return 1 ;;
  esac
}

# The URLs on an npmrc's `@registry-candidates` line(s), one per line.
_workenv_candidates() {
  [ -f "$1" ] || return 0
  sed -n 's/^[;#][[:space:]]*@registry-candidates[[:space:]]*//p' "$1" | tr ' \t' '\n\n' | sed '/^$/d'
}

# Pick the default registry for an env's npmrc; prints "<url>\t<why>" (url may be empty).
_workenv_pick_registry() {
  local org="$1" choice why u first="" mirror=""
  if [ -n "${WORKENV_REGISTRY:-}" ]; then choice="$WORKENV_REGISTRY"; why="this shell (workenv --registry)"
  elif [ -n "${DOTFILES_NPM_REGISTRY:-}" ]; then choice="$DOTFILES_NPM_REGISTRY"; why="this machine (DOTFILES_NPM_REGISTRY)"
  else choice=auto; why=""
  fi
  if [ "$choice" = auto ] && [ -f "$org" ] && grep -q '^[[:space:]]*registry[[:space:]]*=' "$org"; then
    printf '%s\t%s\n' "$(sed -n 's/^[[:space:]]*registry[[:space:]]*=[[:space:]]*//p' "$org" | tail -1)" "fixed in ${org##*/}"
    return 0
  fi
  while IFS= read -r u; do
    [ -z "$first" ] && first="$u"
    case "$u" in *registry.npmjs.org*|*registry.npmjs.com*) ;; *) [ -z "$mirror" ] && mirror="$u" ;; esac
  done <<EOF
$(_workenv_candidates "$org")
EOF
  case "$choice" in
    public) printf '%s\t%s\n' "$DOTFILES_NPM_PUBLIC" "${why}: public"; return 0 ;;
    mirror)
      if [ -n "$mirror" ]; then printf '%s\t%s\n' "$mirror" "${why}: mirror"
      else printf '%s\t%s\n' "$first" "${why}: mirror requested, but ${org##*/} lists none"; fi
      return 0 ;;
    auto) ;;
    *) printf '%s\t%s\n' "$choice" "$why"; return 0 ;;
  esac
  [ -n "$first" ] || { printf '\t%s\n' "npm default"; return 0; }
  while IFS= read -r u; do
    [ -n "$u" ] || continue
    _workenv_reachable "$u" && { printf '%s\t%s\n' "$u" "auto: first reachable candidate"; return 0; }
  done <<EOF
$(_workenv_candidates "$org")
EOF
  # Nothing answered (offline?): keep the preferred one so errors name the registry you expect.
  printf '%s\t%s\n' "$first" "auto: no candidate reachable, using the first"
}

# Build and select this env's npm/pnpm user config (see above). With no <name>.npmrc, npm/pnpm fall
# back to ~/.npmrc.
_workenv_npmrc() {
  local env_file="$1" name="$2" org out picked registry
  org="${env_file%.env}.npmrc"
  if [ -z "$env_file" ] || [ ! -f "$org" ]; then
    unset npm_config_userconfig WORKENV_NPM_REGISTRY WORKENV_NPM_REGISTRY_WHY
    [ -n "${DOTFILES_COREPACK_SET:-}" ] && unset COREPACK_NPM_REGISTRY DOTFILES_COREPACK_SET
    return 0
  fi

  picked="$(_workenv_pick_registry "$org")"
  registry="${picked%%	*}"
  WORKENV_NPM_REGISTRY="$registry"
  WORKENV_NPM_REGISTRY_WHY="${picked#*	}"

  out="$DOTFILES_NPMRC_CACHE/${name:-default}"
  (umask 077; mkdir -p "$DOTFILES_NPMRC_CACHE"
   {
     echo "; Generated by workenv for env \"$name\" — edit ${org/#$HOME/~} instead; this file is rebuilt."
     grep -v '^[[:space:]]*registry[[:space:]]*=' "$org"
     echo
     [ -n "$registry" ] && echo "; default registry: $WORKENV_NPM_REGISTRY_WHY" && echo "registry=$registry"
   } > "$out")
  export npm_config_userconfig="$out"

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
