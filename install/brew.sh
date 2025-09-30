#!/bin/bash

# Xcode
echo "Installing Xcode Command Line Tools"

xcode_path="$(xcode-select -p)"
if [ "$xcode_path" == "/Applications/Xcode.app/Contents/Developer" ] ||
   [ "$xcode_path" == "Library/Developer/CommandLineTools" ]; then
    echo "Xcode already installed"
else
    echo "Installing Xcode..."
    xcode-select --install
 fi
 
echo "Installing Homebrew packages..."
if [ ! -x "$(command -v brew)"  ]; then
    # see https://brew.sh/
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Core tools
brew install coreutils
brew install binutils
brew install diffutils
brew install findutils

# Key commands
brew install gawk
brew install gnu-indent
brew install gnu-sed
brew install gnu-tar
brew install gnu-which
brew install gnu-getopt
brew install gnutls
brew install grep
brew install gzip
brew install watch
brew install wget


# Development tools
brew install git
brew install openssh
brew install openssl@3
brew install neovim
brew install vim
brew install bash
brew install zsh
brew install autojump           # helps you move much quicker than 'cd' command: https://github.com/wting/autojump
brew install html2text          # tool for gathering the readable parts of a webpage

# Media tools
brew install ffmpeg
brew install imagemagick
brew install graphicsmagick

# Databases
brew install postgresql@14 # TODO create zsh alias to postgres vs postgers@14
brew install redis@6.2 # TODO create zsh alias to redis vs redis@6.2
brew install --cask pgadmin4
brew services start postgresql@14
brew services start redis@6.2

# Desktop programs
brew install --cask karabiner-elements # map capslock to escape (tap) and control (press) on MacOS
brew install --cask google-chrome
brew install --cask virtualbox
brew install --cask vagrant
brew install --cask docker
brew install --cask cursor
brew install --cask spotify
brew install --cask webstorm
brew install --cask iterm2
brew install --cask visual-studio-code
brew install --cask MonitorControl # needed to control display volume via mac (https://github.com/MonitorControl/MonitorControl)


# Shell tools
brew install zsh-syntax-highlighting
brew install zsh-autosuggestions
brew install bash-completion@2
brew install bash-git-prompt
brew install tmux

# Go
brew install go # needed for vim-hexokinase

# Node
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

# Python
# Choose the Python versions you want (latest patch for each will be picked by pyenv).
PYTHON_VERSIONS=(
  3.7 3.8 3.9 3.10 3.11 3.12 3.13
)

# Ensure build deps for pyenv (macOS example; adjust for your OS)
install_build_deps() {
  if command -v brew >/dev/null 2>&1; then
    brew update || true
    brew install openssl readline sqlite3 xz zlib bzip2 || true
  else
    echo "Tip: Install Python build deps for your OS (e.g., OpenSSL, zlib, readline)."
  fi
}

# Install pyenv if missing
ensure_pyenv() {
  if ! command -v pyenv >/dev/null 2>&1; then
    echo "pyenv not found. Installing..."
    if command -v brew >/dev/null 2>&1; then
      brew install pyenv || true
    else
      curl -fsSL https://pyenv.run | bash || true
      export PYENV_ROOT="${HOME}/.pyenv"
      export PATH="${PYENV_ROOT}/bin:${PATH}"
    fi
  fi

  # Initialize pyenv in this shell
  export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
  export PATH="${PYENV_ROOT}/bin:${PATH}"
  if command -v pyenv >/dev/null 2>&1; then
    eval "$(pyenv init -)"
  else
    echo "Warning: pyenv still not available; cannot install Python versions." >&2
  fi
}

install_one_version() {
  local short="$1"    # e.g., 3.11
  local full=""

  if ! command -v pyenv >/dev/null 2>&1; then
    echo "Skipping $short: pyenv unavailable." >&2
    return 0
  fi

  # Find latest patch for the series (e.g., 3.11.x)
  if ! full="$(pyenv install -l | awk '{$1=$1};1' | grep -E "^${short//./\\.}\.[0-9]+$" | tail -n1)"; then
    echo "No matching versions for $short" >&2
    return 0
  fi
  if [ -z "$full" ]; then
    echo "No matching versions for $short" >&2
    return 0
  fi

  echo "Installing Python $full ..."
  if ! pyenv install -s "$full"; then
    echo "Warning: failed to install $full; skipping." >&2
    return 0
  fi

  # Create and use a named virtualenv for this Python
  local venv_name="py${full//./_}"
  if command -v pyenv-virtualenv >/dev/null 2>&1; then
    pyenv virtualenv -f "$full" "$venv_name" || true
    pyenv shell "$venv_name" || pyenv local "$venv_name" || true
  else
    # Fallback: use venv module directly
    pyenv shell "$full" || true
    python -m venv "$HOME/.venvs/$venv_name" || {
      echo "Warning: could not create venv for $full" >&2
      return 0
    }
    # shellcheck disable=SC1090
    . "$HOME/.venvs/$venv_name/bin/activate"
  fi

  # Upgrade pip and install common tools in this env
  if command -v python >/dev/null 2>&1; then
    python -m pip install --upgrade pip || true
    python -m pip install --upgrade pip-tools pipx poetry uv || true

    # Ensure pipx path is set up
    if command -v pipx >/dev/null 2>&1; then
      pipx ensurepath || true
    fi

    echo "Installed for $full:"
    python -V || true
    pip -V || true
    poetry --version || true
    uv --version || true
  else
    echo "Warning: python not available after installing $full" >&2
  fi

  # Deactivate if we used venv
  if [ -n "${VIRTUAL_ENV:-}" ]; then
    deactivate || true
  fi

  echo "----------------------------------------"
}

python_main() {
  install_build_deps
  ensure_pyenv

  for ver in "${PYTHON_VERSIONS[@]}"; do
    install_one_version "$ver"
  done

  echo "Done."
}

python_main

exit 0
