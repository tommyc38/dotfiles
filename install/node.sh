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

  local latest
  if ! latest="$(nvm ls-remote "v${major}.*" | awk '{print $1}' | grep -E "^v${major}\." | tail -n1)"; then
    echo "No versions found for major ${major}, skipping."
    return 0
  fi
  if [ -z "$latest" ]; then
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

  npm install -g npm@latest || true
  npm install -g yarn pnpm || {
    echo "Warning: Failed to install yarn/pnpm for ${latest}." >&2
    return 0
  }

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

