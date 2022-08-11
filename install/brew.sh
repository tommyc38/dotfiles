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
brew install binutils
brew install diffutils
brew install findutils

# key commands
brew install ed
brew install gawk
brew install gnu-indent
brew install gnu-sed
brew install gnu-tar
brew install gnu-which
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
brew install neovim
brew install nvm
brew install vim
brew install reattach-to-user-namespace # makes tmux work on mac
brew install bash
brew install zsh
brew install autojump           # helps you move much quicker than 'cd' command
brew install vim --with-python3
brew install html2text          # tool for gathering the readable parts of a webpage

# media tools
brew install ffmpeg
brew install imagemagick

# desktop programs
brew install --cask karabiner-elements # used to map capslock key to ctrl (long press) and esc (tap)
brew install --cask google-chrome
brew install --cask iterm2
brew install --cask virtualbox
brew install --cask virtualbox-extension-pack  # requires password on mac os and authorization in settings
brew install --cask vagrant


# C language tools
brew install cmake
brew install mono               # C# support for YouCompleteMe plugin for Vim
brew install go                 # Go support for YouCompleteMe plugin for Vim

# vagrant
brew cask install virtualbox
brew cask install vagrant

# javascript/typescript tools
brew install node
npm install npm -g
npm install -g typescript

# install python
brew install pyenv pyenv-virtualenv pyenv-virtualenvwrapper


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
