#!/bin/bash

echo "Installing Homebrew packages..."
if [ ! "$(which brew)" ]; then
    echo "Installing Homebrew..." 
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi 


# core tools
brew install coreutils

# key commands
brew install findutils --with-default-names
brew install gawk
brew install gnu-indent --with-default-names
brew install gnu-sed --with-default-names
brew install gnu-tar --with-default-names
brew install gnu-which --with-default-names
brew install grep --with-default-names
brew install gnutls
brew install wdiff --with-gettext
brew install wget

# development tools
brew install git
brew install ssh-copy-id  # replacement for openssh
brew install tmux
brew install bash  # to use this version, /etc/shells needs to be updated with the bash binary location
brew install bash-completion
brew install bash-git-prompt
brew install autojump           # helps you move much quicker than 'cd' command
brew install vim --with-python3
brew install ctags            # index your classes, functions, etc so they populate omnicompleion 
brew install html2text          # tool for gathering the readable parts of a webpage
brew install zsh  # to use this verions, /etc/shells needs to be updated with the zsh binary location
brew install zsh-syntax-highlighting
brew install zsh-autosuggestions
brew install tree

# fonts
brew tap caskroom/fonts
brew cask install font-hack
brew cask install font-roboto-mono
brew cask install font-droid-sans-mono-for-powerline 
brew cask install font-droidsansmono-nerd-font-mono

# desktop programs
brew cask install karabiner-elements
brew cask install google-chrome
brew cask install iterm2
brew cask install insomnia
brew cask install spotify
brew cask install sublime
brew cask install webstorm
brew cask install pycharm

# vagrant
brew cask install virtualbox
brew cask install vagrant

# javascript/typescript tools
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash #Node.js version manager
npm install -g typescript       # Install TypeScript - needed for YouCompleteMe Vim
npm install -g @angular/cli
npm install -g @nrwl/schematics

# install python
brew install python2
pip2 install --upgrade pip setuptools wheel
pip2 install virtualenv
pip2 install virtualenvwrapper

brew install python3
pip3 install --upgrade pip setuptools wheel
pip3 install virtualenv
pip3 install virtualenvwrapper

exit 
