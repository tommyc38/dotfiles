#!/usr/bin/env bash

# Make sure you run this script with 'sudo'
if ! [ $(id -u) = 0 ]; then
   echo "The script need to be run as root." >&2
   exit 1
fi
# Check if Homebrew is installed.  If not, install it
if [[ $(command -v brew) == "" ]]; then
    echo "Installing Hombrew"
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

echo "Installing Homebrew utilities:\n"

echo "Upgrading GNU utilities to their most recent versions"
brew install coreutils 
brew install findutils --with-default-names
brew install gnu-indent --with-default-names
brew install gnu-sed --with-default-names
brew install gnutls
brew install grep --with-default-names
brew install gnu-tar --with-default-names
brew install gawk

echo "Remember that Homebrew prefixes GNU utilities with 'g'"
echo "You can override this by updating your \$PATH variable in your bash_profile\n"

echo "Installing latest version of Vim"
brew install vim

echo "Installing latest version of BASH and ZSH"
brew install bash

echo "Installing python2 and python3"
brew install python2 python3

echo "Setting up BASH as the default terminal"
echo "/usr/local/bin/bash" >> /etc/shells
chsh -s /usr/local/bin/bash

echo "Adding BASE 16 theme"
git clone https://github.com/chriskempson/base16-shell.git ~/.config/base16-shell

echo "Installing Node Version Manager and latest version of Node.js"
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash

echo "Installing Angular CLI and Nx"
npm install -g @angular/cli
npm install -g @nrwl/schematics

echo "Installing Homebrew Cask (to download GUI apps)"
brew install Cask

echo "Installing GUI Apps"
brew cask install google-chrome
brew cask install sketch
brew cask install webstorm
brew cask install insomnia
brew cask install iterm2
brew cask install karabiner-elements

echo "Settig up MacOS default settings"

echo "Disable press-and-hold for keys in favor of key repeat"
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

echo "Set a blazingly fast keyboard repeat rate"
defaults write NSGlobalDomain KeyRepeat -int 2

echo "Set a shorter Delay until key repeat"
defaults write NSGlobalDomain InitialKeyRepeat -int 15

echo "Finder: show all filename extensions"
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

echo "show hidden files by default"
defaults write com.apple.Finder AppleShowAllFiles -bool false

echo "show the ~/Library folder in Finder"
chflags nohidden ~/Library

echo "Show Path bar in Finder"
defaults write com.apple.finder ShowPathbar -bool true
