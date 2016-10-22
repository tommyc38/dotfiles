#!/bin/bash

# Easily create symbolic links to home directory
# clear
echo "
Please Select:

1.) Skip symlinking new dotfiles that already exist in $HOME
2.) Move dotfiles and dotfile-symlinks from $HOME to $HOME/dot_backup and symlink new dotfiles
3.) Resore dotfiles from $HOME/dot_backup
4.) Quit
"
read -p "Enter selection [1-4] > "

DOTFILES=$HOME/dotfiles
BACKUPDIR=$HOME/dot_backup
linkables=$( find -H "$DOTFILES" -maxdepth 3 -name "*.symlink" )

restore(){
    echo -e "\nRestoring from $BACKUPDIR"
    echo "=============================="
    if [ ! $BACKUPDIR ]; then
        echo "$BACKUPDIR does not exist...nothing to backup with!"
        exit
    fi
    if [ $HOME/$(readlink $HOME/karabiner.json) = $DOTFILES/karabiner/karabiner.json.symlink ]; then
        rm $HOME/karabiner.json
    fi
    for file in $( find $BACKUPDIR ! -type d ); do
        target="$HOME/$( basename $file )"
        if [ -L $target ]; then
            sub="$(readlink -e $target)"
            if [ "${sub:0:${#DOTFILES}}" = $DOTFILES ]; then
                echo "Removing symlink: $target --> $(readlink -e $target)"
                rm  $target 
            fi
        else
            echo -e "\n\nWe only remove symlinks from $HOME if they point"
            echo "to $DOTFILES or a subdirectory.  We don't want to"
            echo "remove symlinks that we did not create."
        fi
        if [ -L $file ]; then
            fsub="$(readlink -e $file)"
            if [ "${fsub:0:${#DOTFILES}}" = $DOTFILES ]; then
                echo "Clearing old link in $BACKUP"
                rm $file
            else
                echo "Restoring original symlink: $(readlink -e $file) --> $HOME"
                ln -sr $(readlink -e $file) $HOME
                rm $file
            fi
        else
            echo "Moving $file to original location --> $HOME"
            mv $file $HOME
        fi
    done
    for config in $DOTFILES/config/*;do
        con=$(readlink -e $config)
        if [ "${con:0:${#DOTFILES}}" = $DOTFILES ]; then
            echo "Removed dotfiles symlink."
            rm -r $HOME/.config
            mv $HOME/.config_backup $HOME/.config
            echo "Restored .config backup!"
        else
            echo "No dotfile symlink found for ~/.config"
        fi
    done
}

move(){
    echo -e "\nInitiating dotfile move and creation"
    echo "=============================="
    for file in $linkables; do
        target="$HOME/.$( basename $file ".symlink" )"
        if [ -e $target ]; then
            if [ -L $target ]; then
                tsub=$(readlink -e $target)
                if [ "${tsub:0:${#DOTFILES}}" = $DOTFILES ]; then
                    echo "Symlink already found: $(readlink $target) --> $target"
                else
                    echo "$target is a symbolic link to $(readlink -e $target)" 
                    echo "Moving symbolic link: $(readlink -e $target) --> $BACKUPDIR"
                    ln -sr $(readlink -e $target) $BACKUPDIR
                    echo "Removing old symlink: $target --> $(readlink -e $target)"
                    rm  $target
                    echo "Creating new symlink:  $target --> $file"
                    ln -sr $file $target
                fi
            else
                echo "Moving $target into $BACKUPDIR"
                mv $target $BACKUPDIR
                echo "Creating symbolic: $target --> $file"
                ln -sr $file $target
            fi
        else
            if [ $(basename $file) = "karabiner.json.symlink" ]; then
                if [ -e $HOME/$(basename $file ".symlink") ]; then
                    echo "karabiner.json already exists...Skipping"
                else
                    echo "Creating symlink: $HOME/$(basename $file ".symlink") --> $file"
                    ln -sr $file $HOME/$(basename $file ".symlink")
                fi
            else
                echo "Creating symlink: $target --> $file"
                ln -sr $file $target
            fi
        fi
    done
    echo -e "\n\nInstalling to ~.config"
    echo "=============================="
    if [ ! -d $HOME/.config ]; then
        echo "Creating ~/.config"
        mkdir -p $HOME/.config
        for config in $DOTFILES/config/*; do
            target=$HOME/.config/$( basename $config )
            if [ -e $target ]; then
                echo "~${target#$HOME} already exists... Skipping."
            else
                echo "Creating symlink for $config"
                ln -sr $config $target
            fi
        done
    else 
        echo ".config file found.  Changing it's name to '.config_backup'"
        mv $HOME/.config $HOME/.config_backup
        echo "Creating empty '.config' directoy in $HOME"
        mkdir -p $HOME/.config
        for config in $DOTFILES/config/*; do
            target=$HOME/.config/$( basename $config )
            if [ -e $target ]; then
                echo "~${target#$HOME} already exists... Skipping."
            else
                echo "Creating symlink for $config"
                ln -s $config $target
            fi
        done
    fi
}

check_dot_dir(){
    if [ -d "$BACKUPDIR" ];then
        if [ "$(ls -A $BACKUPDIR)" ]; then
            echo -e "\nA backup directory was found..."
            echo -e "\nFiles in $BACKUPDIR:"
            echo $(ls -a $BACKUPDIR)
        else
            move
        fi
    else
        echo "Creating dotfile backup directory --> $BACKUPDIR"
        mkdir $BACKUPDIR
        move
    fi
}

skip(){
    echo -e "\nCreating dotfile symlinks"
    echo "=============================="
    for file in $linkables ; do
        target="$HOME/.$( basename $file ".symlink" )"
        if [ -e $target ]; then
            echo "~${target#$HOME} already exists... Skipping."
        else
            if [ $(basename $file) = "karabiner.json.symlink" ]; then
                if [ -e $HOME/$(basename $file ".symlink") ];then
                    echo "$HOME/$(basename $file ".symlink") alrady exists...Skipping."
                else
                    echo "Creating symlink: $HOME/$(basename $file ".symlink") --> $file"
                    ln -sr $file $HOME/$(basename $file ".symlink")
                fi
            else
                echo "Creating symlink: $target --> $file"
                ln -sr $file $target
            fi
        fi
    done
    echo -e "\n\nInstalling to ~.config"
    echo "=============================="
    if [ ! -d $HOME/.config ]; then
        echo "Creating ~/.config"
        mkdir -p $HOME/.config
        for config in $DOTFILES/config/*; do
            target=$HOME/.config/$( basename $config )
            if [ -e $target ]; then
                echo "~${target#$HOME} already exists... Skipping."
            else
                echo "Creating symlink for $config"
                ln -sr $config $target
            fi
        done
    else
        echo "~.config file found...Skipping."
    fi
    echo -e "\n\nInstalling to Vim"
    echo "=============================="
    if [ ! -d $HOME/.vim ]; then
        echo "Creating .vim files"
        mkdir -p $HOME/.vim
        for vims in $DOTFILES/vim/*; do
            target=$HOME/.vim/$( basename $vims )
            if [ -e $target ]; then
                echo "~${target#$HOME} already exists... Skipping."
            else
                echo "Creating symlink for $config"
                ln -sr $config $target
            fi
        done
    else
        echo "~.config file found...Skipping."
    fi
}
case $REPLY in
    1)    skip
          exit
          ;;
    2)    check_dot_dir
          exit
          ;;
    3)    restore
          exit
          ;;
    4)    echo "Program Terminated"
          exit
          ;;
esac
