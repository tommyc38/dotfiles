#!/bin/bash

# Make sure you run this script with 'sudo'
if ! [ $(id -u) = 0 ]; then
   echo "The script need to be run as root." >&2
   exit 1
fi

echo "Initializing..."


if [ "$(uname)" == "Darwin" ]; then
    echo "Running on OSX"

    echo "Creating symlinks"
    sh install/symlink.sh "1"

    echo "Setting up Vim configs"
    sh install/vim.sh "1"

    echo "Setting up IDE tools"
    sh install/brew.sh

    echo "Setting up ZSH as the default terminal"
    echo "/usr/local/bin/bash" >> /etc/shells
    echo "/usr/local/bin/zsh" >> /etc/shells
    chsh -s /usr/local/bin/zsh

    echo "Setting up base16 themes"
    git clone https://github.com/chriskempson/base16-shell.git ~/.config/base16-shell

    echo "Setting up Karabiner"
    $KARABINER=$HOME/.config/karabiner/
    if [ -d $KARABINER ];then
	    if [ -e $KARABINER/karabiner.json ];then
		    mv $KARABINER/karabiner.json $KARABINER/karabiner-old.json
	    fi
	ln -s $HOME/dotfiles/karabiner/karabiner.json $KARABINER
    else
    	mkdir -p ~/.config/karabiner	    
	ln -s $HOME/dotfiles/karabiner/karabiner.json $KARABINER
    fi


    # echo "Symlinkng Tmux plugins folder to ~"
    # ln -s ~/dotfiles/tmux/tmux.d ~/.tmux
    # echo "Plugins symlinked.  Don't forget to install plugins"

    echo "Updating OSX settings"
    sh install/osx.sh

elif [["$(uname)" == "TODO"]]; then
    echo "Running on Ubuntu"

    echo "Updated 'apt-get'"
else
    echo "Sorry, OS not recognized"
fi

# echo "Configuring zsh as default shell"
# sudo dscl . change /users/$USER UserShell $SHELL /usr/local/bin/zsh

echo "Done."
