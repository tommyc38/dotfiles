#!/usr/bin/env bash

DOTFILES=$HOME/dotfiles
BACKUPDIR=$HOME/dot_backup
linkables=$( find -H "$DOTFILES" -maxdepth 3 -name "*.symlink" )
extention=".symlink"

get_name(){
    local file="$1"
    local result="$HOME/.$(basename $file $extention)"
    echo $result 
}

sym_sym(){
    local file="$(get_name $1)"
    [ -L $file ] && [ -e $BACKUPDIR/$(basename $file) ] && echo "$(basename $file) exits in $BACKUPDIR!" && return 0
    [ -L $file ] && ln -s $(readlink -f $file) $BACKUPDIR/$(basename $file) &> /dev/null && rm -r $file && echo "Resymlinking: $file --> $BACKUPDIR"
}
file_exists(){
    local file="$1"
    [ -e $(get_name $file) ] 
}
check_move(){
    local reply="$1"
    [ $reply = "2" ]
}
move_file(){
    local file="$(get_name $1)"
    if [ -e $BACKUPDIR/$(basename $file) ]; then
        echo "Cant move $(basename $file); $(basename $file) exits in $BACKUPDIR!"
    else
        echo "Moving $file --> $BACKUPDIR"
        mv $file $BACKUPDIR
    fi
}
symlink(){
    local file="$1"
    echo "Creating symlink: $(get_name $file) --> $file"
    ln -s $file $(get_name $file)
}

restore(){
    local file="$1"
    local answer="$2"
    home_file_name=$(get_name $file)
    if [ $answer = "3" ] && [ -e $BACKUPDIR/$(basename $home_file_name) ] && [ $file = $(readlink -f $home_file_name) ]; then
        local backup_fname="$BACKUPDIR/$(basename $home_file_name)"
        echo "Removing $home_file_name"
        rm $home_file_name
        if [ -L $backup_fname ]; then
            echo "Resoring original symlink: $(readlink -f $backup_fname) --> $HOME"
            ln -s "$(readlink -f $backup_fname)" $HOME
            rm $BACKUPDIR/$(basename $home_file_name)
        else
            echo "Moving original file: $backup_fname --> $HOME"
            mv $BACKUPDIR/$(basename $home_file_name) $HOME
        fi
    else
        [ ! -e $BACKUPDIR/$(basename $home_file_name) ] && [ $answer = "3" ] && echo "No backup file ($home_file_name) found!" && return 0
        return 1
    fi
}
main(){
    local reply="$1"
    for file in $linkables;do
        if check_move $reply; then
            if file_exists $file; then
                [ ! -e $BACKUPDIR ] && mkdir $BACKUPDIR
                sym_sym $file || move_file $file
                home_file_name=$(get_name $file)
                if [ $file = $(readlink -f $home_file_name) ]; then
                    echo " $(basename $file) already symlinked --> $HOME" 
                else    
                    symlink $file
                fi
            else
                symlink $file
            fi
        elif restore $file $reply; then
            :
        else
            if file_exists $file; then
                echo "Found $(get_name $file) ...Skipping"
            else
                symlink $file
            fi
        fi
    done
    [ $reply = "3" ] && [ -e $BACKUPDIR ] && [ -z "$(ls -A $BACKUPDIR)" ] && rm -d $BACKUPDIR && echo -e "$BACKUPDIR removed \n All files restored!"
}
if [[ ! -z "$1" ]]; then
    REPLY="$1"
    main $REPLY
else
    echo "
    Please Select:

    1.) Skip symlinking new dotfiles that already exist in $HOME
    2.) Move dotfiles and dotfile-symlinks from $HOME to $HOME/dot_backup and symlink new dotfiles
    3.) Resore dotfiles from $HOME/dot_backup
    4.) Quit
    "
    read -p "Enter selection [1-4] > "
    case $REPLY in
        1)    main $REPLY
            exit
            ;;
        2)    main $REPLY
            exit
            ;;
        3)    main $REPLY
            exit
            ;;
        4)    echo "Program Terminated"
            exit
            ;;
    esac
fi
exit 0
