#!/bin/bash
#
# Install Homebrew (if missing), trust the third-party taps, and install everything in ../Brewfile.
# Safe to re-run: `brew bundle` only installs/upgrades what's missing.

set -uo pipefail

DOTFILES="${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
BREWFILE="$DOTFILES/Brewfile"

# Taps whose formulae/casks Homebrew refuses to load until they're trusted (`brew trust`).
# Keep in sync with the `tap` lines in the Brewfile.
TRUSTED_TAPS=(atlassian/acli hashicorp/tap terraform-linters/tap)

if [[ -x /opt/homebrew/bin/brew ]]; then
  HOMEBREW_PREFIX=/opt/homebrew
else
  HOMEBREW_PREFIX=/usr/local
fi

if [[ ! -x "$HOMEBREW_PREFIX/bin/brew" ]]; then
  # Interactive on purpose: the installer needs sudo, and in NONINTERACTIVE mode it only tries
  # `sudo -n` (ignoring cached credentials), which fails on a fresh Mac.
  echo "Installing Homebrew (asks for your password and to press RETURN)..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  [[ -x /opt/homebrew/bin/brew ]] && HOMEBREW_PREFIX=/opt/homebrew
fi
if [[ ! -x "$HOMEBREW_PREFIX/bin/brew" ]]; then
  echo "ERROR: Homebrew is not installed; every later step depends on it." >&2
  exit 1
fi

# A freshly installed brew isn't on PATH yet (Apple Silicon puts it in /opt/homebrew).
eval "$("$HOMEBREW_PREFIX/bin/brew" shellenv)"

for tap in "${TRUSTED_TAPS[@]}"; do
  brew tap "$tap" >/dev/null
  # `brew trust` only exists on newer Homebrew; older versions load taps without it.
  if brew commands 2>/dev/null | grep -qx trust; then
    brew trust "$tap" >/dev/null
  fi
done

echo "Installing packages from $BREWFILE..."
# Don't abort the whole install if one cask fails (e.g. an app that was installed by hand).
if ! brew bundle --file "$BREWFILE"; then
  echo "WARNING: some Brewfile entries failed; re-run 'brew bundle --file $BREWFILE' to see which." >&2
fi

exit 0
