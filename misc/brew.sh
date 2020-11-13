#!/bin/bash

# Xcode
echo "Installing Xcode Command Line Tools"

if test $(xcode-select -p) == "/Applications/Xcode.app/Contents/Developer"; then
    echo "Xcode already installed"
else
    echo "Installing Xcode..."
    xcode-select --install
 fi
 
echo "Installing Homebrew packages..."
if [ ! "$(which brew)" ]; then
    echo "Installing Homebrew..." 
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi 

# core tools
brew install coreutils

# key commands
brew install pango
brew install binutils
brew install diffutils
brew install ed --default-names
brew install findutils --with-default-names
brew install gawk
brew install frei0r
brew install ffmpeg
brew install imagemagick@6
brew install gnu-indent --with-default-names
brew install gnu-sed --with-default-names
brew install gnu-tar --with-default-names
brew install gnu-which --with-default-names
brew install gnutls
brew install grep
brew install gzip
brew install screen
brew install watch
brew install wdiff --with-gettext
brew install wget

# development tools
brew install bash
brew install zsh
brew install zsh-syntax-highlighting
brew install zsh-autosuggestions
brew install git
brew install ssh-copy-id  # replacement for openssh
brew install bash  # to use this version, /etc/shells needs to be updated with the bash binary location
brew install neovim
brew install docker
brew install openssh
brew install tmux
brew install reattach-to-user-namespace # makes tmux work on mac
brew install autojump           # helps you move much quicker than 'cd' command
brew install tree
brew install vim --with-python3
brew install html2text          # tool for gathering the readable parts of a webpage

# fonts
brew tap caskroom/fonts
brew cask install font-hack
brew cask install font-roboto-mono
brew cask install font-jetbrains-mono
brew cask install font-droid-sans-mono-for-powerline 
brew cask install font-droid-sansm-ono-nerd-font-mono


# desktop programs
brew cask install karabiner-elements
brew cask install google-chrome
brew cask install google-cloud-sdk
brew cask install webstorm
brew cask install pycharm
brew cask install insomnia
brew cask install iterm2
brew cask install virtualbox
brew cask install vagrant

# C language tools
brew install cmake
brew install go                


# javascript/typescript tools
brew install node             
npm install npm -g           
npm install -g typescript      
npm install -g ts-node
npm install -g angular-cli
npm install -g firebase-tools
npm install tsserver-client     
npm install xbuild             
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.0/install.sh | bash #install nvm

# install python
brew install python@3.9
brew install pyenv

exit 
