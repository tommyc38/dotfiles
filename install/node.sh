#!/bin/bash

# Node majors to preinstall (latest patch of each). Older versions a repo pins in .nvmrc are installed
# on demand by bin/repo.sh --npm-install; anything below 16 has no arm64 build and compiles from source.
NODE_MAJOR_VERSIONS=(18 20 22 24)
NVM_VERSION="v0.40.3"

# Install nvm if not present
# (nvm is a shell function, so `command -v nvm` is always false in a fresh bash — check the files.)
if [ ! -s "${NVM_DIR:-$HOME/.nvm}/nvm.sh" ]; then
  echo "nvm not found. Installing..."
  export NVM_DIR="${HOME}/.nvm"
  mkdir -p "$NVM_DIR"
  # PROFILE=/dev/null stops the installer appending to ~/.zshrc (a file in this repo).
  curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | PROFILE=/dev/null bash
  # shellcheck disable=SC1090
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  # shellcheck disable=SC1090
  [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
else
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  # shellcheck disable=SC1090
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
fi

# If nvm still isn't available, continue but warn (won't be able to install)
if ! command -v nvm >/dev/null 2>&1; then
  echo "Warning: Failed to load nvm; cannot install Node versions." >&2
fi

install_for_major() {
  local major="$1"

  if ! command -v nvm >/dev/null 2>&1; then
    echo "Skipping v${major}: nvm unavailable." >&2
    return 0
  fi

  # version-remote prints just the version. Don't parse `nvm ls-remote`: it puts "->" in front of the
  # version in use, so awk '{print $1}' dropped it and re-runs installed the previous patch alongside it.
  local latest
  latest="$(nvm version-remote "$major" 2>/dev/null)"
  if [[ "$latest" != "v${major}."* ]]; then
    echo "No versions found for major ${major}, skipping."
    return 0
  fi

  echo "Installing Node ${latest}..."
  if ! nvm install "$latest"; then
    echo "Warning: Failed to install Node ${latest}, skipping." >&2
    return 0
  fi
  nvm use "$latest" >/dev/null 2>&1 || true

  if ! command -v npm >/dev/null 2>&1; then
    echo "Warning: npm not found after installing ${latest}; skipping yarn/pnpm for this version." >&2
    return 0
  fi

  # npm@latest only supports recent Node majors (npm 12 needs 22.22+). On older ones, stay on the newest
  # release of the bundled npm major instead (e.g. npm@^10 on Node 18/20).
  if ! npm install -g npm@latest --loglevel=error 2>/dev/null; then
    npm install -g "npm@^$(npm -v | cut -d. -f1)" --loglevel=error || true
  fi
  # npm 11.19+ blocks package install scripts unless they're allowed; pnpm uses one to set up its binary.
  npm install -g --allow-scripts=pnpm,yarn yarn pnpm || true
  if ! pnpm -v >/dev/null 2>&1 || ! yarn -v >/dev/null 2>&1; then
    echo "Warning: yarn/pnpm don't run under Node ${latest}. Fix the error above, then re-run: ./install.sh --only node" >&2
  fi

  echo "Installed:"
  node -v || true
  npm -v || true
  yarn -v || true
  pnpm -v || true
  echo "----------------------------------------"
}

for major in "${NODE_MAJOR_VERSIONS[@]}"; do
  install_for_major "$major"
done

# New shells use the newest installed version (zshrc resolves this alias without loading nvm's slow path).
command -v nvm >/dev/null 2>&1 && nvm alias default node >/dev/null

echo "Node Install Done."

