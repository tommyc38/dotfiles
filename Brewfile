# Homebrew bundle — everything install/brew.sh installs.
#
#   brew bundle --file ~/dotfiles/Brewfile            # install / upgrade
#   brew bundle check --file ~/dotfiles/Brewfile      # anything missing?
#   brew bundle cleanup --file ~/dotfiles/Brewfile    # what's installed but NOT listed here (dry run)
#
# Third-party taps must be trusted before Homebrew will load them; install/brew.sh runs
# `brew trust` for every tap listed in TRUSTED_TAPS there. Keep the two lists in sync.

tap "atlassian/acli"
tap "hashicorp/tap"
tap "terraform-linters/tap"

# --- GNU userland (the shell configs put these first on PATH) -------------------------------------
brew "coreutils"
brew "binutils"
brew "diffutils"
brew "findutils"
brew "gawk"
brew "gnu-indent"
brew "gnu-sed"
brew "gnu-tar"
brew "gnu-which"
brew "gnu-getopt"          # bin/vault, bin/repo.sh and bin/workenv.sh need GNU getopt
brew "gnutls"
brew "grep"
brew "gzip"
brew "watch"
brew "wget"

# --- Shells & terminal ----------------------------------------------------------------------------
brew "bash"
brew "zsh"
brew "bash-completion@2"
brew "bash-git-prompt"
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"
brew "tmux"
brew "autojump"
brew "fzf"
brew "ripgrep"
brew "fd"
brew "bat"
brew "jq"
brew "yq"
brew "html2text"
brew "shellcheck"         # lint for the scripts in bin/ and install/

# --- Editors --------------------------------------------------------------------------------------
brew "neovim"
brew "vim"
brew "go"                  # vim-hexokinase builds with go

# --- Git, code hosting & issue tracking -----------------------------------------------------------
brew "git"
# No Homebrew openssh: Apple's /usr/bin/ssh is what supports UseKeychain / ssh-add --apple-use-keychain
# (bin/ssh-setup.sh), and the Homebrew bottle breaks whenever openssl@3 moves ahead of it.
brew "openssl@3"
brew "gh"                  # GitHub + Tungsten Cloud GHE (bin/dev-auth.sh logs both in)
brew "atlassian/acli/acli" # Atlassian CLI: Jira / Confluence (bin/dev-auth.sh)
brew "azure-cli"           # Azure DevOps (cs-infrastructure) — `az extension add -n azure-devops`

# --- Languages & runtimes (Node is managed by nvm, Python by pyenv — see install/) ----------------
brew "pyenv"
brew "pyenv-virtualenv"
brew "openjdk@21"
brew "openjdk@25"          # JAVA_HOME in zshrc/bashrc points here

# --- Infrastructure -------------------------------------------------------------------------------
brew "hashicorp/tap/terraform"
brew "terraform-docs"
cask "terraform-linters/tap/tflint"
brew "trivy"
brew "kubernetes-cli"

# --- Docs, media & misc ---------------------------------------------------------------------------
brew "pandoc"
brew "lcov"
brew "ffmpeg"
brew "imagemagick"
brew "graphicsmagick"

# --- Databases ------------------------------------------------------------------------------------
# postgresql@14 and redis@6.2 were disabled upstream in 2026; these are the supported successors.
brew "postgresql@17", restart_service: :changed
brew "redis", restart_service: :changed
cask "pgadmin4"

# --- Desktop apps ---------------------------------------------------------------------------------
cask "karabiner-elements"  # caps lock = escape (tap) / control (hold); config in karabiner/
cask "iterm2"
cask "webstorm"            # settings come from JetBrains Settings Sync — see README
cask "cursor"
cask "visual-studio-code"
cask "docker-desktop"
cask "google-chrome"
cask "spotify"
cask "monitorcontrol"      # external display brightness/volume from the keyboard
cask "virtualbox"
