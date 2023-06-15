
####################
# functions
####################

# print available colors and their numbers
function colours() {
    for i in {0..255}; do
        printf "\x1b[38;5;${i}m colour${i}"
        if (( $i % 5 == 0 )); then
            printf "\n"
        else
            printf "\t"
        fi
    done
}

# Create a new directory and enter it
function md() {
    mkdir -p "$@" && cd "$@"
}

function hist() {
    history | awk '{a[$2]++}END{for(i in a){print a[i] " " i}}' | sort -rn | head
}

# find shorthand
function f() {
    find . -name "$1"
}

# Start an HTTP server from a directory, optionally specifying the port
# function server() {
    # local port="${1:-8000}"
    # open "http://localhost:${port}/"
    # Set the default Content-Type to `text/plain` instead of `application/octet-stream`
    # And serve everything as UTF-8 (although not technically correct, this doesn’t break anything for binary files)
    # python -c $'import SimpleHTTPServer;\nmap = SimpleHTTPServer.SimpleHTTPRequestHandler.extensions_map;\nmap[""] = "text/plain";\nfor key, value in map.items():\n\tmap[key] = value + ";charset=UTF-8";\nSimpleHTTPServer.test();' "$port"
# }

# take this repo and copy it to somewhere else minus the .git stuff.
function gitexport(){
    mkdir -p "$1"
    git archive master | tar -x -C "$1"
}

# get gzipped size
function gz() {
    echo "orig size    (bytes): "
    cat "$1" | wc -c
    echo "gzipped size (bytes): "
    gzip -c "$1" | wc -c
}

# Escape UTF-8 characters into their 3-byte format
function escape() {
    printf "\\\x%s" $(printf "$@" | xxd -p -c1 -u)
    echo # newline
}

# Decode \x{ABCD}-style Unicode escape sequences
function unidecode() {
    perl -e "binmode(STDOUT, ':utf8'); print \"$@\""
    echo # newline
}

# Extract archives - use: extract <file>
# Credits to http://dotfiles.org/~pseup/.bashrc
function extract() {
    if [ -f $1 ] ; then
        case $1 in
            *.tar.bz2) tar xjf $1 ;;
            *.tar.gz) tar xzf $1 ;;
            *.bz2) bunzip2 $1 ;;
            *.rar) rar x $1 ;;
            *.gz) gunzip $1 ;;
            *.tar) tar xf $1 ;;
            *.tbz2) tar xjf $1 ;;
            *.tgz) tar xzf $1 ;;
            *.zip) unzip $1 ;;
            *.Z) uncompress $1 ;;
            *.7z) 7z x $1 ;;
            *) echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# syntax highlight the contents of a file or the clipboard and place the result on the clipboard
function hl() {
    if [ -z "$3" ]; then
        src=$( pbpaste )
    else
        src=$( cat $3 )
    fi

    if [ -z "$2" ]; then
        style="moria"
    else
        style="$2"
    fi

    echo $src | highlight -O rtf --syntax $1 --font Inconsoloata --style $style --line-number --font-size 24 | pbcopy
}

# set the background color to light
function light() {
    export BACKGROUND="light" && source ~/.zshrc
}

function dark() {
    export BACKGROUND="dark" && source ~/.zshrc 
}
function changez(){
    if grep -inE '^#\sbase16*|^#\s\[ -n "\$PS1*' $HOME/.zshrc &> /dev/null; then
        sed -i --follow-symlinks "s/# BASE/BASE/" $HOME/.zshrc
        sed -i --follow-symlinks "s/# \[ -n \"\$PS/\[ -n \"\$PS/" $HOME/.zshrc
    elif grep -inE '^base16*|^\[ -n "\$PS1*' $HOME/.zshrc &> /dev/null; then
        sed -i --follow-symlinks "s/BASE/# BASE/" $HOME/.zshrc
        sed -i --follow-symlinks "s/\[ -n \"\$PS/# \[ -n \"\$PS/" $HOME/.zshrc
    else
        echo "Check you .zshrc file, something is wrong."
    fi
}

load-nvmrc() {
  if command -v nvm &>/dev/null; then
    local node_version="$(nvm version)"
    local nvmrc_path="$(nvm_find_nvmrc)"

    if [ -n "$nvmrc_path" ]; then
      local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

      if [ "$nvmrc_node_version" = "N/A" ]; then
        nvm install
      elif [ "$nvmrc_node_version" != "$node_version" ]; then
        nvm use
      fi
    elif [ "$node_version" != "$(nvm version default)" ]; then
      echo "Reverting to nvm default version"
      nvm use default
    fi
  fi
}

workenv() {
  # We have to run the command in the current environment to set/unset variables
  . workenv.sh "$@"
}

function changeu(){
    #TODO remove autojump from dotfiles
    #TODO change zsh-sytax-highlight path in .zshrc
    if grep -inE '^#\sbase16*|^#\s\[ -n "\$PS1*' $HOME/.zshrc &> /dev/null; then
        sed -i --follow-symlinks "s/# BASE/BASE/" $HOME/.zshrc
        sed -i --follow-symlinks "s/# \[ -n \"\$PS/\[ -n \"\$PS/" $HOME/.zshrc
    elif grep -inE '^base16*|^\[ -n "\$PS1*' $HOME/.zshrc &> /dev/null; then
        sed -i --follow-symlinks "s/BASE/# BASE/" $HOME/.zshrc
        sed -i --follow-symlinks "s/\[ -n \"\$PS/# \[ -n \"\$PS/" $HOME/.zshrc
    else
        echo "Check you .zshrc file, something is wrong."
    fi
}
