#!/bin/bash

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

  # Special handling for Python 3.13
  local venv_name
  if [ "$short" = "3.13" ]; then
    venv_name="nvim-provider"
  else
    venv_name="py${full//./_}"
  fi

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

    # Special handling for Python 3.13 - install pynvim
    if [ "$short" = "3.13" ]; then
      echo "Installing pynvim for nvim-provider environment..."
      python -m pip install pynvim || true
      
      # Echo the full path of the virtual environment
      if command -v pyenv-virtualenv >/dev/null 2>&1; then
        local venv_path
        venv_path="$(pyenv prefix "$venv_name" 2>/dev/null || echo "$HOME/.pyenv/versions/$venv_name")"
        echo "nvim-provider virtual environment path: $venv_path"
      else
        echo "nvim-provider virtual environment path: $HOME/.venvs/$venv_name"
      fi
    fi

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
