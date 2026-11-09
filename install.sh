#!/bin/bash
#
# Set up a new Mac (or re-converge an existing one) from this dotfiles repo.
#
#   ./install.sh                       # prompts for the vault password
#   VAULT_PASSWORD=... ./install.sh    # non-interactive
#   ./install.sh --only brew,auth      # run a subset of steps
#   ./install.sh --skip fonts,repos    # run everything except some steps
#   ./install.sh --list                # list the steps
#
# Every step is idempotent, so re-running after a failure (or months later) is safe.

set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES
cd "$DOTFILES" || exit 1

STEPS=(xcode brew vault symlinks ssh node python vault-install claude fonts macos shell base16 repos auth)

describe() {
  case "$1" in
    xcode)         echo "Xcode Command Line Tools" ;;
    brew)          echo "Homebrew + Brewfile packages and apps" ;;
    vault)         echo "Decrypt vault/ to vault-key/ (SSH keys, env files, repo lists)" ;;
    symlinks)      echo "Symlink dotfiles, vim, karabiner, VS Code, and vault-key/symlinks.txt" ;;
    ssh)           echo "Load SSH keys into the agent / macOS keychain" ;;
    node)          echo "nvm + Node versions" ;;
    python)        echo "pyenv + Python versions + nvim-provider" ;;
    vault-install) echo "Run vault-key/install.sh (machine-specific extras)" ;;
    claude)        echo "Claude Code CLI + user plugins (Nx) + MCP servers (Atlassian, Playwright, Context7)" ;;
    fonts)         echo "Google, Nerd and Powerline fonts" ;;
    macos)         echo "macOS defaults (Finder, key repeat, ...)" ;;
    shell)         echo "Make Homebrew zsh the login shell" ;;
    base16)        echo "Clone base16-shell themes" ;;
    repos)         echo "Clone repos from vault-key/**/*.repos.txt and install their packages" ;;
    auth)          echo "Log in to GitHub, GHE, Jira, Bitbucket, AWS SSO (bin/dev-auth.sh)" ;;
  esac
}

usage() {
  cat <<EOF
Usage: ./install.sh [--only a,b] [--skip a,b] [--list] [-h|--help] [vault_password]

The vault password can also come from \$VAULT_PASSWORD or vault-key/password.txt; otherwise you're
prompted. Passing it as an argument still works but leaves it in your shell history.

Steps (in order):
EOF
  for s in "${STEPS[@]}"; do printf '  %-14s %s\n' "$s" "$(describe "$s")"; done
}

only=
skip=
password_arg=
while [ $# -gt 0 ]; do
  case "$1" in
    --only) only="${2:-}"; shift 2 ;;
    --only=*) only="${1#*=}"; shift ;;
    --skip) skip="${2:-}"; shift 2 ;;
    --skip=*) skip="${1#*=}"; shift ;;
    --list|-h|--help) usage; exit 0 ;;
    -*) echo "Unknown option: $1" >&2; usage; exit 1 ;;
    *) password_arg="$1"; shift ;;
  esac
done

for s in ${only//,/ } ${skip//,/ }; do
  [[ " ${STEPS[*]} " == *" $s "* ]] || { echo "Unknown step: $s (see --list)" >&2; exit 1; }
done

should_run() {
  local s="$1"
  [ -n "$only" ] && [[ ",$only," != *",$s,"* ]] && return 1
  [ -n "$skip" ] && [[ ",$skip," == *",$s,"* ]] && return 1
  return 0
}

if [ "$(uname)" != "Darwin" ]; then
  echo "ERROR: This script is designed for macOS only" >&2
  exit 1
fi

if [ "$(id -u)" = 0 ]; then
  echo "ERROR: Do not run this script with sudo; it asks for sudo only where needed." >&2
  exit 1
fi

load_brew() {
  if [[ -x /opt/homebrew/bin/brew ]]; then HOMEBREW_PREFIX=/opt/homebrew; else HOMEBREW_PREFIX=/usr/local; fi
  [[ -x "$HOMEBREW_PREFIX/bin/brew" ]] && eval "$("$HOMEBREW_PREFIX/bin/brew" shellenv)"
  # bin/vault and friends need GNU getopt/coreutils, which the shell rc normally puts on PATH.
  export PATH="$HOMEBREW_PREFIX/opt/gnu-getopt/bin:$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin:$PATH"
}
load_brew

failed=()
run_step() {
  local s="$1"; shift
  should_run "$s" || return 0
  echo
  echo "========================================"
  echo "▶ $s — $(describe "$s")"
  echo "========================================"
  if ! "$@"; then
    echo "✗ step '$s' failed (continuing; re-run with --only $s)" >&2
    failed+=("$s")
  fi
}

# --- Steps ----------------------------------------------------------------------------------------

step_xcode() {
  if xcode-select -p &>/dev/null; then
    echo "Xcode Command Line Tools already installed"
    return 0
  fi
  echo "Installing Xcode Command Line Tools — finish the dialog, then re-run ./install.sh"
  xcode-select --install
  exit 0
}

step_brew() { bash "$DOTFILES/install/brew.sh" && load_brew; }

vault_password() {
  if [ -n "$password_arg" ]; then
    VAULT_PASSWORD="$password_arg"
  elif [ -z "${VAULT_PASSWORD:-}" ] && [ -s "$DOTFILES/vault-key/password.txt" ]; then
    VAULT_PASSWORD="$(cat "$DOTFILES/vault-key/password.txt")"
  fi
  if [ -z "${VAULT_PASSWORD:-}" ] && { : </dev/tty; } 2>/dev/null; then
    read -rsp "Vault password: " VAULT_PASSWORD </dev/tty
    echo
  fi
  [ -n "${VAULT_PASSWORD:-}" ]
}

step_vault() {
  # Decrypting replaces vault-key/ wholesale. If it holds edits that were never encrypted (workenv
  # rewrites ~/.workrc, `pnpm dev:setup` rewrites ~/.npmrc — both link into vault-key/), a re-run
  # would silently swap them for the older vault/ copies. Keep them and say so instead.
  local newest unsaved
  newest="$(find "$DOTFILES/vault" -type f -not -name .DS_Store -print0 2>/dev/null | xargs -0 ls -t 2>/dev/null | head -1)"
  if [ -n "$newest" ] && [ -d "$DOTFILES/vault-key" ]; then
    unsaved="$(find "$DOTFILES/vault-key" -path '*/vault_backups' -prune -o -type f -not -name .DS_Store -newer "$newest" -print 2>/dev/null)"
    if [ -n "$unsaved" ]; then
      echo "vault-key/ has changes newer than vault/ — NOT decrypting over them:"
      echo "$unsaved" | sed "s#^$DOTFILES/#  #"
      echo "Keep them: 'vault -e' and commit. Discard them: 'vault' (old copies go to vault-key/vault_backups/)."
      return 0
    fi
  fi
  vault_password || { echo "A vault password is required" >&2; return 1; }
  mkdir -p "$DOTFILES/vault-key"
  # Passed via the environment, not argv, so it never shows up in `ps`.
  VAULT_PASSWORD="$VAULT_PASSWORD" bash "$DOTFILES/bin/vault"
}

# ~/.gitconfig stays a real, local file whose first lines include git/gitconfig.
ensure_gitconfig() {
  local shared="$DOTFILES/git/gitconfig" gc="$HOME/.gitconfig" tmp
  [ -L "$gc" ] && rm "$gc"   # older setups symlinked it into the repo
  if [ -f "$gc" ] && git config --file "$gc" --get-all include.path 2>/dev/null | grep -qxF "$shared"; then
    echo "~/.gitconfig already includes ${shared/#$HOME/~}"
    return 0
  fi
  tmp="$(mktemp)"
  printf '# Machine-local git config. Shared settings come from the include below (dotfiles repo).
[include]
	path = %s

' "$shared" > "$tmp"
  [ -f "$gc" ] && cat "$gc" >> "$tmp"
  mv "$tmp" "$gc"
  echo "~/.gitconfig now includes ${shared/#$HOME/~}"
}

step_symlinks() {
  ensure_gitconfig
  bash "$DOTFILES/bin/symlink.sh" --include-vim --include-karabiner --include-editors || return 1
  if [ -f "$DOTFILES/vault-key/symlinks.txt" ]; then
    bash "$DOTFILES/bin/symlink.sh" --file "$DOTFILES/vault-key/symlinks.txt"
  else
    echo "No vault-key/symlinks.txt found, skipping vault symlinks"
  fi
  prune_dangling_vault_links
}

# Links into vault-key/ whose source no longer exists (a key or file was renamed or removed in the vault,
# e.g. ~/.ssh/main -> vault-key/main after the personal/tungsten reorganization). Only our own links go.
prune_dangling_vault_links() {
  local link dir
  for dir in "$HOME/.ssh" "$HOME/.certs"; do
    [ -d "$dir" ] || continue
    for link in "$dir"/* "$dir"/.[!.]*; do
      [ -L "$link" ] && [ ! -e "$link" ] || continue
      case "$(readlink "$link")" in
        "$DOTFILES/vault-key/"*) rm "$link" && echo "Removed stale link: ${link/#$HOME/~}" ;;
      esac
    done
  done
}

step_ssh() { bash "$DOTFILES/bin/ssh-setup.sh"; }

# Give npm/pnpm the environment a shell in ~/dotfiles would have: the work env + layered npm user config
# (shell/workenv-auto.sh) and the Tungsten CA when it's present (needed to reach the Artifactory mirror).
load_npm_env() {
  [ -f "$HOME/.certs/tungsten-ca-chain.pem" ] && export NODE_EXTRA_CA_CERTS="$HOME/.certs/tungsten-ca-chain.pem"
  # shellcheck disable=SC1091
  . "$DOTFILES/shell/workenv-auto.sh"
  _workenv_auto   # install.sh runs from $DOTFILES, so this picks the env for ~/dotfiles
}

# Machines differ: some can reach public npm, some (corporate filters) only a mirror. workenv picks each
# env's default registry from its "@registry-candidates" line by probing them; say what it chose here.
npm_network_hint() {
  echo "npm/pnpm for env ${WORKENV_NAME:-none}: ${WORKENV_NPM_REGISTRY:-npm default} (${WORKENV_NPM_REGISTRY_WHY:-no env .npmrc})"
  case "${WORKENV_NPM_REGISTRY_WHY:-}" in
    *"no candidate reachable"*)
      echo "⚠ none of the env's registry candidates answer from this network. Connect the VPN, or set"
      echo "  DOTFILES_NPM_REGISTRY=<url> in ~/.config/dotfiles/local.sh, then re-run: ./install.sh --only node" ;;
  esac
  [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/npmrc" ] && echo "⚠ ~/.config/dotfiles/npmrc is no longer read — move its registry to DOTFILES_NPM_REGISTRY in local.sh"
  return 0
}

step_node() { load_npm_env; npm_network_hint; bash "$DOTFILES/install/node.sh"; }
step_python() { bash "$DOTFILES/install/python.sh"; }

step_vault_install() {
  if [ -f "$DOTFILES/vault-key/install.sh" ]; then
    bash "$DOTFILES/vault-key/install.sh"
  else
    echo "No vault-key/install.sh found, skipping"
  fi
}

step_claude() { load_npm_env; bash "$DOTFILES/install/claude.sh"; }

step_fonts() {
  bash "$DOTFILES/bin/fonts.sh" --google-fonts-light --nerd-fonts-light --powerline-fonts-light
}

step_macos() { bash "$DOTFILES/install/osx.sh"; }

step_shell() {
  local zsh_path="$HOMEBREW_PREFIX/bin/zsh" bash_path="$HOMEBREW_PREFIX/bin/bash" sh
  [ -x "$zsh_path" ] || { echo "Homebrew zsh not installed (run the brew step)"; return 1; }
  for sh in "$bash_path" "$zsh_path"; do
    if [ -x "$sh" ] && ! grep -qxF "$sh" /etc/shells; then
      echo "Adding $sh to /etc/shells (requires sudo)"
      echo "$sh" | sudo tee -a /etc/shells >/dev/null
    fi
  done
  if [ "$(dscl . -read "/Users/$USER" UserShell | awk '{print $2}')" = "$zsh_path" ]; then
    echo "Login shell is already $zsh_path"
  else
    chsh -s "$zsh_path"
  fi
}

step_base16() {
  if [ -d "$HOME/.config/base16-shell" ]; then
    echo "base16-shell already installed"
  else
    git clone https://github.com/chriskempson/base16-shell.git "$HOME/.config/base16-shell"
  fi
}

step_repos() {
  # repo.sh needs nvm and the SSH keys/agent from the earlier steps.
  local repos_file rc=0
  # repo.sh switches the work env + npm config per repo folder, exactly like cd-ing into it in a shell.
  load_npm_env
  while IFS= read -r -d '' repos_file; do
    echo "Processing repositories from ${repos_file#"$DOTFILES"/}..."
    bash "$DOTFILES/bin/repo.sh" --file "$repos_file" --default-directory "$HOME/dev" --npm-install || rc=1
  done < <(find "$DOTFILES/vault-key" -path '*/vault_backups' -prune -o -name '*.repos.txt' -type f -print0 2>/dev/null)
  return $rc
}

step_auth() {
  if [ -t 0 ]; then
    bash "$DOTFILES/bin/dev-auth.sh"
  else
    bash "$DOTFILES/bin/dev-auth.sh" --check
  fi
}

# --- Run ------------------------------------------------------------------------------------------

echo "Dotfiles: $DOTFILES"
for s in "${STEPS[@]}"; do
  run_step "$s" "step_${s//-/_}"
done

echo
echo "========================================"
if [ ${#failed[@]} -eq 0 ]; then
  echo "✅ Done."
else
  echo "⚠️  Done with failures in: ${failed[*]}"
  echo "   Fix and re-run: ./install.sh --only $(IFS=,; echo "${failed[*]}")"
fi
echo "========================================"
echo
echo "Next steps:"
echo "  1. Open a new terminal (or: exec zsh)"
echo "  2. ./bin/validate-install.sh"
echo "  3. WebStorm: sign in to your JetBrains account and turn on Settings Sync (see README)"
echo "  4. Tungsten repos: run 'pnpm dev:setup' in one of them (npm mirror, CA chain, CodeArtifact)"
[ ${#failed[@]} -eq 0 ]
