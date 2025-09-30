#!/bin/bash

# Node
NODE_MAJOR_VERSIONS=(10 12 14 16 18 20 22)

# Install nvm if not present
if ! command -v nvm >/dev/null 2>&1; then
  echo "nvm not found. Installing..."
  export NVM_DIR="${HOME}/.nvm"
  mkdir -p "$NVM_DIR"
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
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

echo "Node Install Done."

