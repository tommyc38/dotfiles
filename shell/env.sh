# Environment shared by zsh (zsh/zshrc.symlink) and bash (bash/bash_profile.symlink).
#
# Must stay valid in both zsh and macOS's bash 3.2: no arrays, no glob qualifiers, no [[ =~ ]].
# Everything here is cheap and non-interactive, because IntelliJ/WebStorm source ~/.zshrc with
# INTELLIJ_ENVIRONMENT_READER set just to harvest PATH, JAVA_HOME and node for Gradle/Nx.

export DOTFILES="${DOTFILES:-$HOME/dotfiles}"

# --- Homebrew & GNU tools -------------------------------------------------------------------------
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
if [ -n "$HOMEBREW_PREFIX" ]; then
  # GNU versions without the g prefix (bin/ scripts rely on GNU getopt, readlink -f, sed, ...).
  for _gnu in coreutils findutils gnu-sed gnu-tar gnu-which gnu-indent grep; do
    if [ -d "$HOMEBREW_PREFIX/opt/$_gnu/libexec/gnubin" ]; then
      export PATH="$HOMEBREW_PREFIX/opt/$_gnu/libexec/gnubin:$PATH"
      export MANPATH="$HOMEBREW_PREFIX/opt/$_gnu/libexec/gnuman:$MANPATH"
    fi
  done
  unset _gnu
  export PATH="$HOMEBREW_PREFIX/opt/gnu-getopt/bin:$PATH"
fi

# --- Paths & editor -------------------------------------------------------------------------------
export NVIM="$HOME/.config/nvim"
export VIM_PLUGINS="$HOME/.vim/plugged"
export VIM_THEME_FILE="$DOTFILES/vim/custom-plugins/darcula/colors/darcula.vim"
export CUSTOM_BIN="$DOTFILES/bin/"
export VMS="$HOME/vagrant_boxes/"
export ANDROID_HOME="$HOME/Library/Android/sdk"
export EDITOR="nvim"

[ -d "$HOME/bin" ] && export PATH="$HOME/bin:$PATH"
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"   # pipx, AWS CLI v2, claude
export PATH="$DOTFILES/bin:$PATH"
export PATH="/Applications/WebStorm.app/Contents/MacOS:$PATH"      # `webstorm .`

# --- Node (nvm) -----------------------------------------------------------------------------------
# Put nvm's default node on PATH without loading nvm (its own default lookup costs ~1.5s per shell).
# The rc files load nvm itself (with --no-use) for interactive shells. Handles node/stable, "22",
# "v22.1.0"; sort -V so v22.20 beats v22.9. Anything else (lts/*, ...) is left to `nvm use` in the rc.
export NVM_DIR="$HOME/.nvm"
export NVM_SYMLINK_CURRENT=true   # gives IDEs one stable path for the current node version
_nvm_default=""
[ -f "$NVM_DIR/alias/default" ] && _nvm_default="$(cat "$NVM_DIR/alias/default")"
case "$_nvm_default" in
  node|stable|"") _nvm_pat="v*" ;;
  v[0-9]*|[0-9]*) _nvm_pat="v${_nvm_default#v}" ;;
  *) _nvm_pat="" ;;
esac
DOTFILES_NVM_DEFAULT_BIN=""
if [ -n "$_nvm_pat" ] && [ -d "$NVM_DIR/versions/node" ]; then
  _nvm_ver="$(find "$NVM_DIR/versions/node" -mindepth 1 -maxdepth 1 \( -name "$_nvm_pat" -o -name "$_nvm_pat.*" \) \
    -exec basename {} \; 2>/dev/null | sort -V | tail -1)"
  if [ -n "$_nvm_ver" ] && [ -x "$NVM_DIR/versions/node/$_nvm_ver/bin/node" ]; then
    DOTFILES_NVM_DEFAULT_BIN="$NVM_DIR/versions/node/$_nvm_ver/bin"
    export PATH="$DOTFILES_NVM_DEFAULT_BIN:$PATH"
    export NVM_BIN="$DOTFILES_NVM_DEFAULT_BIN"
  fi
fi
unset _nvm_default _nvm_pat _nvm_ver

# --- Python (pyenv) -------------------------------------------------------------------------------
export PYENV_ROOT="$HOME/.pyenv"
[ -d "$PYENV_ROOT/bin" ] && export PATH="$PYENV_ROOT/bin:$PATH"

# --- Java -----------------------------------------------------------------------------------------
# Gradle needs a launch JVM on PATH before it can honour a project's toolchain, and Homebrew's
# openjdk is keg-only so it is never linked into PATH for us.
for _java_home in \
    /opt/homebrew/opt/openjdk@25/libexec/openjdk.jdk/Contents/Home \
    /usr/local/opt/openjdk@25/libexec/openjdk.jdk/Contents/Home; do
  if [ -x "$_java_home/bin/java" ]; then
    export JAVA_HOME="$_java_home"
    export PATH="$JAVA_HOME/bin:$PATH"
    break
  fi
done
unset _java_home

# --- Tungsten Cloud -------------------------------------------------------------------------------
# `pnpm dev:setup` writes its env as a marked block at the end of ~/.zshrc (it picks the rc file
# from $SHELL). zsh runs that block itself; bash (and install.sh) evaluate the same block from there.
dotfiles_load_tng_block() {
  local block
  block="$(sed -n '/^# >>> tng dev:setup >>>$/,/^# <<< tng dev:setup <<<$/p' "$DOTFILES/zsh/zshrc.symlink" 2>/dev/null)"
  [ -n "$block" ] && eval "$block"
}

# --- This machine only ----------------------------------------------------------------------------
# ~/.config/dotfiles/ is never synced. local.sh is for settings that differ per computer (paths,
# corporate proxies, extra PATH entries, ...). Its siblings: npmrc (machine npm/pnpm defaults, see
# shell/workenv-auto.sh) and workenv-dirs.txt (folder → work environment for this machine).
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/local.sh" ] && . "${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/local.sh"
