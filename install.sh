#!/bin/bash

echo "Initializing..."


if [ "$(uname)" == "Darwin" ]; then
    echo "Running on OSX"

    echo "Setting up IDE tools"
    sh install/ide.sh

    echo "Installing Powerline Fonts"
    sh pfonts/install.sh

    echo "Installing Nerd Fonts" 
    cd ~/Library/Fonts && curl -fLo "Droid Sans Mono for Powerline Nerd Font Complete.otf" https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/patched-fonts/DroidSansMono/complete/Droid%20Sans%20Mono%20for%20Powerline%20Nerd%20Font%20Complete.otf

    echo "Creating symlinks"
    sh install/symlink.sh "1"

    echo "Setting up base16 themes"
    sh install/base16.sh

    # echo "Setting up Karabiner"
    #TODO

    echo "Setting up Vim"
    sh install/vim.sh "1"

    echo "Installing Vim Plugins"
    vim -E -c PlugInstall -c q
    
    echo "Running YCM post install hook"
    sh install/YCM.sh

    echo "Symlinkng Tmux plugins folder to ~"
    ln -s ~/dotfiles/tmux/tmux.d ~/.tmux
    echo "Plugins symlinked.  Don't forget to install plugins"

    # echo "Updating OSX settings"
    # sh install/osx.sh

elif [["$(uname)" == "TODO"]]; then
    echo "Running on Ubuntu"

    echo "Updated 'apt-get'"
else
    echo "Sorry, OS not recognized"
fi

echo "Configuring zsh as default shell"
sudo dscl . change /users/$USER UserShell $SHELL /usr/local/bin/zsh

echo "Done."
