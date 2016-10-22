#!/bin/bash
DOTFILES=$HOME/dotfiles
VIMSYMS=("$DOTFILES/vim/MySnips" "$DOTFILES/vim/autoload" "$DOTFILES/vim/plugins.vim")
VIMCREATE=("_backup" "_swaps" "sessions")
VIMBACKUP=$HOME/.vim_backup

echo -e "\n\nInstalling Vim"
echo "=============================="

run(){
    for vims in $VIMFILES; do
        target=$HOME/.vim/$( basename $vims )
        if [ -e $target ]; then
            echo "~${target#$HOME} already exists... Skipping."
        else
            echo "Creating symlink: $target --> $vims"
            ln -s $vims $target
        fi
    done
    for create in $VIMCREATE; do
        target=$HOME/.vim/$create
        if [ -e $target ]; then
            echo "~${target#$HOME} already exists...Skipping"
        else
            echo "Creating vim files/directories"
            mkdir $HOME/.vim/$create
        fi
    done
}
skip(){
    if [ ! -d $HOME/.vim ]; then
        mkdir $HOME/.vim
        run
    else 
        echo "$.vim file found...Skipping"
    fi
}
moving(){
    if [ -d $HOME/.vim ]; then
        echo ".vim file found.  Moving to $VIMBACKUP"
        mv $HOME/.vim $VIMBACKUP
        run
    else 
        echo "No .vim found.  Setting up Vim..."
        mkdir $HOME/.vim
        run
    fi
}
backup(){
    if [ -e $VIMBACKUP ]; then
        echo "Moving original vim file back in place."
        rm -r .vim
        mv $VIMBACKUP $HOME/.vim
    else
        echo "No vim_backup file found!"
    fi
}
if [ ! -z $1 ];then
    skip; exit
else
    echo "
    Please Select:

    1.) Skip that are already installed in $HOME/.vim
    2.) Backup the current .vim directory (if present) and install new vim settings
    3.) Resore .vim back to its previous settings
    4.) Quit
    "
    read -p "Enter selection [1-4] > "
    case $REPLY in
        1)    skip
            exit
            ;;
        2)    moving
            exit
            ;;
        3)    backup
            exit
            ;;
        4)    echo "Program Terminated"
            exit
            ;;
    esac
fi
exit
