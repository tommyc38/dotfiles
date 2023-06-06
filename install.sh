#!/bin/bash

script_path="$(dirname -- "$( readlink -f -- "$0")")"

# Make sure you run this script with 'sudo'
if [ ! "$(id -u)" = 0 ]; then
   echo "The script need to be run as root." >&2
   exit 1
fi

echo "Initializing..."

if [ "$(uname)" == "Darwin" ]; then
    echo "Running on OSX"

    echo "Creating Dotfile Symlinks..."
    sh install/symlink.sh -v -k
    source ~/.bash_profile

    echo "Installing System Packages & Desktop Applications..."
    sh install/brew.sh

    echo "Decrypting Vault Files.."
    sh bin/vault

    if [ -e "$script_path/vault-key/install.sh" ]; then
      echo "Running Vault-Key Install..."
      sh vault-key/install.sh
    fi

    echo "Installing Fonts..."
    sh install/fonts.sh --google-fontslight --nerd-fonts-light --powerline-fonts-light

    echo "Setting ZSH as the Default Terminal"
    # In order to change a user's default login shell, the shell must be added to /etc/shells first (MacOS).
    # These are the updated versions of bash and zsh installed by homebrew.
    [ -z "$(cat < /etc/shells | grep "/usr/local/bin/bash")" ] && echo "/usr/local/bin/bash" >> /etc/shells
    [ -z "$(cat < /etc/shells | grep "/usr/local/bin/zsh")" ] && echo "/usr/local/bin/zsh" >> /etc/shells
    # Because this script is ran with sudo we need to apply it to the user running the sudo command.
    chsh -s /usr/local/bin/zsh "$SUDO_USER"

    echo "Installing Base16 Themes"
    [ ! -e ~/.config/base16-shell ] && git clone https://github.com/chriskempson/base16-shell.git ~/.config/base16-shell

    # echo "Symlinkng Tmux plugins folder to ~"
    # ln -s ~/dotfiles/tmux/tmux.d ~/.tmux
    # echo "Plugins symlinked.  Don't forget to install plugins"

    echo "Updating OSX settings"
    sh install/osx.sh

elif [ "$(uname)" = "TODO" ]; then
    echo "Running on Ubuntu"
    echo "Updated 'apt-get'"
else
    echo "Sorry, OS not recognized"
fi

# echo "Configuring zsh as default shell"
# sudo dscl . change /users/$USER UserShell $SHELL /usr/local/bin/zsh

echo "Done."
