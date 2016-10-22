#!/bin/bash

echo "Installing Homebrew packages..."
if [ ! "$(which brew)" ]; then
    echo "Installing Homebrew..." 
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi 

# core tools
brew install coreutils

# key commands
brew install binutils
brew install homebrew/dupes/diffutils
brew install findutils --with-default-names
brew install gawk
brew install gnu-indent --with-default-names
brew install gnu-sed --with-default-names
brew install gnu-tar --with-default-names
brew install gnu-which --with-default-names
brew install gnutls
brew install homebrew/dupes/gzip
brew install wdiff --with-gettext
brew install wget

# development tools
brew install git
brew install ssh-copy-id  # replacement for openssh
brew install tmux
brew install reattach-to-user-namespace # makes tmux work on mac
brew install bash  # to use this version, /etc/shells needs to be updated with the bash binary location
brew install bash-completion
brew install bash-git-prompt
brew install zsh  # to use this verions, /etc/shells needs to be updated with the zsh binary location
brew install autojump           # helps you move much quicker than 'cd' command
brew install vim --with-python3
brew install ctags            # index your classes, functions, etc so they populate omnicompleion 
brew install html2text          # tool for gathering the readable parts of a webpage
brew install zsh-syntax-highlighting
brew install zsh-autosuggestions
brew install tree

# desktop programs
brew cask install karabiner-elements
brew cask install google-chrome
brew cask install iterm2
brew cask install dropbox
brew cask install spotify
brew cask install sublime

# C language tools
brew install cmake
brew install mono               # C# support for YouCompleteMe plugin for Vim
brew install go                 # Go support for YouCompleteMe plugin for Vim

# vagrant
brew cask install virtualbox
brew cask install vagrant

# javascript/typescript tools
brew install node               # JavaScript and TypeScript support for YouCompleteMe Vim
npm install npm -g              # Update npm
npm install -g typescript       # Install TypeScript - needed for YouCompleteMe Vim
npm install -g tsserver-client     # Needed for TypeScript and YouCompleteMe
npm install -g xbuild              # Needed for TypeScript and YouCompleteMe
npm install -g jshint   # javascript linting with syntastic

# install python
brew install python
pip install --upgrade pip setuptools wheel
pip install flake8
pip install virtualenv
pip install virtualenvwrapper

brew install python3
pip3 install --upgrade pip setuptools wheel
pip3 install flake8
pip3 install virtualenv
pip3 install virtualenvwrapper

exit 
