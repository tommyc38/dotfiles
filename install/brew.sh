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

exit 0
