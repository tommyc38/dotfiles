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
brew install binutils
brew install diffutils
brew install ed --default-names
brew install findutils --with-default-names
brew install gawk
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
brew install git
brew install openssh
brew install tmux
brew install reattach-to-user-namespace # makes tmux work on mac
brew install bash
brew install zsh
brew install autojump           # helps you move much quicker than 'cd' command
brew install vim --with-python3
brew install html2text          # tool for gathering the readable parts of a webpage

# desktop programs
brew cask install karabiner
brew cask installe seil
brew cask install google-chrome
brew cask install iterm2

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
npm install tsserver-client     # Needed for TypeScript and YouCompleteMe
npm install xbuild              # Needed for TypeScript and YouCompleteMe

# install python
brew install python
pip install --upgrade setuptools
pip install --upgrade pip
pip install flake8
pip install virtualenv
pip install virtualenvwrapper

brew install python3
pip3 install --upgrade setuptools
pip3 install --upgrade pip
pip3 install flake8
pip3 install virtualenv
pip3 install virtualenvwrapper

echo "Creating virtualenv directory"
mkdir ~/.virtualenvs

if test $(which virtualenvwrapper.sh); then
    echo "Setting up python2 virtualenvs..."
    mkvirtualenv py2
    workon py2
    if test $VIRTUAL_ENV; then
        pip install --upgrade setuptools
        pip install --upgrade pip
        pip install flake8
        pip install requests
        pip install jinja2
        pip install flask
        pip install scrapy
        pip install beautifulsoup
        pip install ipython
    else
        deactivate
        echo "py2 virtualenv not setup!"
    fi
    echo "Setting up python2 virtualenvs..."
    mkvirtualenv py3
    workon py3
    if test $VIRTUAL_ENV; then
        pip install --upgrade setuptools
        pip install --upgrade pip
        pip install flake8
        pip install requests
        pip install jinja2
        pip install flask
        pip install scrapy
        pip install beautifulsoup
        pip install ipython
    else
        deactivate
        echo "py3 virtualenv not setup!"
    fi

else
    echo "You need to make put the virtualenvwrapper.sh file in /usr/local/bin"
    echo "See http://stackoverflow.com/questions/12647266/where-is-virtualenvwrapper-sh-after-pip-install"
fi

echo "Installing Nerd Fonts"
sh ./fonts.sh Hack
sh ./fonts.sh DroidSans
echo Installing Powerline Fonts
sh ./pfonts.sh
exit 
