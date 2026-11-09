#!/bin/bash
#
# workenv --doctor: will every repo in the mapped folders find its npm registries and tokens?
#
# For each "<directory> <env>" in the workenv-dirs maps it checks, without changing anything:
#   - the env file exists, and every ${VAR} in its <env>.npmrc is exported by <env>.env;
#   - the default registry workenv would pick on this network (and whether it answers);
#   - every repo .npmrc under the folder:
#       ✗ a ${VAR} the env doesn't export. npm (and pnpm, for a repo's default registry) prefer the repo's
#         line over the env's credentials, so they'd send the literal "${VAR}" text and get a 401.
#       ⚠ a registry the repo uses that has no credentials anywhere (fine if it allows anonymous reads).
# Plus leftovers from older setups (~/.config/dotfiles/npmrc, tokens or registry= in ~/.npmrc).
#
# Only variable NAMES and registry hosts are printed, never values. Exit status 1 if anything is ✗.

DOTFILES="${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck disable=SC1091
. "$DOTFILES/shell/workenv-auto.sh"

if [ -t 1 ]; then G=$'\033[0;32m' Y=$'\033[1;33m' R=$'\033[0;31m' B=$'\033[1m' N=$'\033[0m'; else G= Y= R= B= N=; fi
problems=0
warnings=0
ok()   { printf '  %s✓%s %s\n' "$G" "$N" "$*"; }
warn() { printf '  %s⚠%s %s\n' "$Y" "$N" "$*"; warnings=$((warnings + 1)); }
bad()  { printf '  %s✗%s %s\n' "$R" "$N" "$*"; problems=$((problems + 1)); }
tilde() { local t='~'; printf '%s' "${1/#$HOME/$t}"; }

# Lines of an npmrc that aren't comments.
active() { grep -v -E '^[[:space:]]*([;#]|$)' "$1" 2>/dev/null; }
exports_of() { sed -nE 's/^export ([A-Za-z_][A-Za-z0-9_]*)=.*/\1/p' "$1"; }
vars_in() { printf '%s\n' "$1" | grep -oE '\$\{[A-Za-z_][A-Za-z0-9_]*\}' | tr -d '${}' | sort -u; }
# "host/path/" of every credential line (//host/path/:_authToken=..., :_password=, :_auth=)
auth_keys() { printf '%s\n' "$1" | sed -nE 's#^[[:space:]]*//([^[:space:]]+):(_authToken|_password|_auth)[[:space:]]*=.*#\1#p'; }
# The registry URLs an npmrc sets, as "<scope or ->\t<url>"
registries_in() {
  printf '%s\n' "$1" | sed -nE 's#^[[:space:]]*(@[^:[:space:]]+):registry[[:space:]]*=[[:space:]]*([^[:space:]]+).*#\1	\2#p; s#^[[:space:]]*registry[[:space:]]*=[[:space:]]*([^[:space:]]+).*#-	\1#p'
}
is_public() { case "$1" in *registry.npmjs.org*|*registry.npmjs.com*|*registry.yarnpkg.com*) return 0 ;; esac; return 1; }
# host/path/ form of a URL (scheme and default port dropped, trailing slash added)
url_key() { local u="${1#*://}"; u="${u/:443\//\/}"; printf '%s/\n' "${u%/}"; }
# Value of VAR in an env, read in a subshell (only used to expand registry HOSTNAMES like ${NPM_REGISTRY_URL})
env_value() { ( . "$1" >/dev/null 2>&1; printenv "$2" ); }
in_list() { printf '%s\n' "$2" | grep -qxF "$1"; }

# Expand ${VAR} in a registry URL from the env (names validated; no eval).
expand_url() {
  local url="$1" env_file="$2" v
  for v in $(vars_in "$url"); do
    url="${url//\$\{$v\}/$(env_value "$env_file" "$v")}"
  done
  printf '%s\n' "$url"
}

# Does any credential key in $2 (one per line) cover URL $1? npm matches the longest key prefix.
covered() {
  local key want
  want="$(url_key "$1")"
  while IFS= read -r key; do
    [ -n "$key" ] || continue
    case "$want" in "${key%/}/"*) return 0 ;; esac
  done <<EOF
$2
EOF
  return 1
}

check_repo_npmrc() {
  local f="$1" env_name="$2" env_file="$3" exported="$4" org_keys="$5" candidates="$6"
  local dir repo pm text v scope url usable line key var repo_keys=""
  dir="$(dirname "$f")"
  repo="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$dir")"
  pm=npm
  [ -f "$repo/pnpm-lock.yaml" ] || [ -f "$dir/pnpm-lock.yaml" ] && pm=pnpm
  text="$(active "$f")"
  [ -n "$text" ] || return 0

  for v in $(vars_in "$text"); do
    case "$v" in HOME|USER|PWD) continue ;; esac
    in_list "$v" "$exported" || bad "$(tilde "$f") ($pm) needs \${$v}, which env '$env_name' doesn't export — add it to $(tilde "$env_file") (an alias of the right token)"
  done

  # Credentials the repo file itself provides and the tool will actually use.
  while IFS= read -r line; do
    key="$(auth_keys "$line")"
    [ -n "$key" ] || continue
    var="$(vars_in "$line")"
    if [ -z "$var" ]; then repo_keys="$repo_keys$key"$'\n'
    elif [ "$pm" = npm ] && in_list "$var" "$exported"; then repo_keys="$repo_keys$key"$'\n'
    fi   # pnpm: ${VAR} credentials in a repo .npmrc are ignored for scoped registries — count on the env's
  done <<EOF
$text
EOF

  while IFS='	' read -r scope url; do
    [ -n "$url" ] || continue
    url="$(expand_url "$url" "$env_file")"
    if [ "$scope" = - ]; then
      is_public "$url" && continue
      in_list "${url%/}/" "$candidates" && continue   # the env's own mirror candidates are anonymous
    fi
    if covered "$url" "$org_keys" || covered "$url" "$repo_keys"; then
      :
    else
      warn "$(tilde "$f") uses $([ "$scope" = - ] && echo "default registry" || echo "$scope →") $(url_key "$url") with no credentials in env '$env_name' (fine if it allows anonymous reads)"
    fi
  done <<EOF
$(registries_in "$text")
EOF
}

check_folder() {
  local dir="$1" env_name="$2" env_file org exported org_text org_keys candidates picked v f count=0 before
  env_file="$(_workenv_file_for_name "$env_name")"
  printf '\n%s%s%s → %s\n' "$B" "$(tilde "$dir")" "$N" "$env_name"
  if [ -z "$env_file" ]; then bad "no vault-key/**/$env_name.env"; return; fi
  org="${env_file%.env}.npmrc"
  exported="$(exports_of "$env_file")"
  if [ -f "$org" ]; then
    org_text="$(active "$org")"
    for v in $(vars_in "$org_text"); do
      in_list "$v" "$exported" || bad "$(tilde "$org") uses \${$v}, which $(basename "$env_file") doesn't export"
    done
    org_keys="$(auth_keys "$org_text")"
    candidates="$(_workenv_candidates "$org" | sed 's#/*$#/#')"
    picked="$(WORKENV_REGISTRY= _workenv_pick_registry "$org")"
    local reg="${picked%%$'\t'*}" why="${picked#*$'\t'}"
    case "$why" in
      *"no candidate reachable"*) warn "default registry: none of the candidates answer from this network (would use $reg)" ;;
      *) ok "default registry: ${reg:-npm default} ($why)" ;;
    esac
  else
    warn "no $(tilde "$org"): npm/pnpm fall back to ~/.npmrc in this folder"
  fi
  [ -d "$dir" ] || { warn "folder doesn't exist on this machine"; return; }

  before=$((problems + warnings))
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    count=$((count + 1))
    check_repo_npmrc "$f" "$env_name" "$env_file" "$exported" "$org_keys" "$candidates"
  done < <(find "$dir" -maxdepth 4 \( -name node_modules -o -name .git -o -name dist \) -prune -o -name .npmrc -type f -print 2>/dev/null | sort)
  [ $((problems + warnings)) -eq "$before" ] && ok "$count repo .npmrc file(s) resolve with env '$env_name'"
}

printf '%sworkenv doctor%s — npm/pnpm registries and tokens per folder (names only, never values)\n' "$B" "$N"

# Each mapped folder once (machine-local map wins on the same folder, like workenv itself).
seen=""
for map in "$DOTFILES_LOCAL_DIR/workenv-dirs.txt" "$WORKENV_DIRS_FILE"; do
  [ -f "$map" ] || continue
  while read -r dir name _ || [ -n "$dir" ]; do
    case "$dir" in ""|\#*) continue ;; esac
    dir="$(_workenv_expand "$dir")"; dir="${dir%/}"
    in_list "$dir" "$seen" && continue
    seen="$seen$dir"$'\n'
    check_folder "$dir" "$name"
  done < "$map"
done

printf '\n%sLeftovers%s\n' "$B" "$N"
leftovers=$((problems + warnings))
[ -f "$DOTFILES_LOCAL_DIR/npmrc" ] && warn "$(tilde "$DOTFILES_LOCAL_DIR/npmrc") is no longer read — put its registry in DOTFILES_NPM_REGISTRY (~/.config/dotfiles/local.sh) and delete it"
if [ -f "$HOME/.npmrc" ]; then
  grep -qE '^[[:space:]]*registry[[:space:]]*=' "$HOME/.npmrc" && warn "~/.npmrc sets registry= (Tungsten dev:setup in mirror mode?) — re-run it with TNG_SETUP_REGISTRY=public; workenv picks the registry"
  active "$HOME/.npmrc" | grep -E ':(_authToken|_password|_auth)[[:space:]]*=' | grep -vqE '=[[:space:]]*\$\{' && warn "~/.npmrc has a literal token (written by a tool?) — move it into an env file as \${VAR}"
fi
[ $((problems + warnings)) -eq "$leftovers" ] && ok "none"

echo
if [ "$problems" -gt 0 ]; then
  printf '%s%d problem(s)%s, %d warning(s)\n' "$R" "$problems" "$N" "$warnings"; exit 1
fi
printf '%sNo problems%s, %d warning(s)\n' "$G" "$N" "$warnings"
