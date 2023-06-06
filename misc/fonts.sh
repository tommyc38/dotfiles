#!/bin/bash
#
# Brief description of your script
# Copyright 2021 tomconley

# Create a temporary directory and store its name in a variable ...
temp_dir="$(mktemp -d)"
font_install_dir=

# Terminal output color terminator
clear='\033[0m'

google_fonts_light=("Roboto")
powerline_fonts_light=("Hack" "Droid Sans Mono for Powerline" "Fira Mono for Powerline" "Roboto Mono for Powerline" "Go Mono for Powerline")
nerd_fonts_light=("Hack Nerd Font" "Go Mono Nerd Font""Fira Code Nerd Font" "Droid Sans Mono Nerd Font" "Roboto Mono Nerd Font" "JetBrains Mono")

# Font download urls
google_fonts_url="https://github.com/google/fonts/archive/main.zip"
nerd_fonts_url=""
powerline_fonts_url="https://github.com/powerline/fonts.git"
jetbrains_fonts_url=""

# Fonts download directories
google_fonts_download_dir="${temp_dir}/google"
nerd_fonts_download_dir="${temp_dir}/nerd"
powerline_fonts_download_dir="${temp_dir}/powerline"
jetbrains_fonts_download_dir="${temp_dir}/jetbrains"

# Fonts install directories
google_fonts_install_dir="${font_install_dir}/google-fonts"
nerd_fonts_install_dir="${font_install_dir}/nerd-fonts"
powerline_fonts_install_dir="${font_install_dir}/powerline-fonts"
jetbrains_fonts_install_dir="${font_install_dir}/jetbrains-fonts"

# Fonts to install (either empty or "true")
will_install_google_fonts=
will_install_google_fonts_light=
will_install_nerd_fonts=
will_install_nerd_fonts_light=
will_install_powerline_fonts=
will_install_powerline_fonts_light=
will_install_jetbrains_fonts=

function install_powerline_fonts() {
  # if an argument is given it is used to select which fonts to install
  local prefix="$1"
  if [[ ! -d $powerline_fonts_download_dir   ]]; then
    git clone "$powerline_fonts_url" "$powerline_fonts_download_dir" --depth=1
  fi
  if [[ ! -d $powerline_fonts_install_dir   ]]; then
    mkdir -p "${powerline_fonts_install_dir}"
  fi
  # Copy all fonts to user fonts directory
  if [[ -n $prefix   ]]; then
    echo "Installing Powerline Font - ${prefix}..."
  else
    echo "Installing Powerline Fonts..."
  fi
  find "$powerline_fonts_download_dir" \( -name "$prefix*.[ot]tf" -or -name "$prefix*.pcf.gz" \) -type f -print0  | xargs -0 -n1 -I % cp "%" "$powerline_fonts_install_dir/"
}

#######################################
# Returns the font directory in which fonts will be installed to
# Globals:
#   HOME - The users home directory
# Arguments:
#   STORE_IN_USER_OR_SYSTEM - Any non-empty string will signify to store the fonts at the user level (system is default)
#######################################
function get_font_install_dir() {
  if test "$(uname)" = "Darwin"; then
    # MacOS
    local font_system_dir="/System/Library/Fonts"
    local font_user_dir="$HOME/Library/Fonts"
  else
    # Linux
    local font_system_dir="/usr/local/share/fonts"
    local font_user_dir="$HOME/.fonts"
  fi
  if [[ -n $1 ]]; then
    if [[ ! -f $font_user_dir && $( uname) != "Darwin" ]]; then
      mkdir -p "$font_user_dir"
    fi
    echo "$font_user_dir"
  else
    echo "$font_system_dir"
  fi
}

function color_blue() {
  local color_blue="\033[0;34m"
  echo -ne $color_blue$1$clear
}

function color_green() {
  local color_green="\033[0;32m"
  echo -ne $color_green$1$clear
}

function color_cyan() {
  local color_cyan="\033[0;36m"
  echo -ne $color_cyan$1$clear
}

function menu_font_install_dir() {
  local answer
  echo -en "
Do you want fonts installed to the system (everyone) or user (just you)?
$(color_cyan '1.)') User
$(color_cyan '2.)') System
$(color_cyan '3.)') Exit
$(color_blue 'Choose an option:') "
  read -r answer
  case "$answer" in
    1) font_install_dir="$(get_font_install_dir "true")" ;;
    2) font_install_dir="$(get_font_install_dir)" ;;
    3) exit 0 ;;
    *) exit 0 ;;
  esac
}

function menu_font_select() {
  local answer
  echo -ne "
Choose Fonts To Install
$(color_cyan '1.)') Install All
$(color_cyan '2.)') Install All - Light
$(color_cyan '3.)') Install Google Fonts (500MB)
$(color_cyan '4.)') Install Google Fonts - Light (500MB)
$(color_cyan '5.)') Install Nerd Fonts
$(color_cyan '6.)') Install Nerd Fonts - Light
$(color_cyan '7.)') Install JetBrains Font
$(color_cyan '8.)') Install Powerline Fonts
$(color_cyan '9.)') Install Powerline Fonts - Light
$(color_cyan '10.)') Select Fonts
$(color_cyan '11.)') Exit
$(color_blue 'Choose an option:') "
  read -r answer
  case $answer in
    1) ;;
    2) will_install_google_fonts="true" ;;
    3) will_install_nerd_fonts="true" ;;
    4) will_install_jetbrains_fonts="true" ;;
    5) will_install_powerline_fonts="true" install_powerline_fonts ;;
    6) ;;
    7) exit 0 ;;
    *) exit 0 ;;
  esac
}

function parse_options() {
  # Parse options
  local short="aAgGnNpPhi"
  local long="all,all-light,google,google-light,nerd,nerd-light,powerline,powerline-light,help,interactive"

  # $@ is all command line parameters passed to the script.
  # -o is for short options like -v
  # -l is for long options with double dash like --version
  # the comma separates different long options
  # -a is for long options with single dash like -version
  local options=$(getopt --long "${long}" -o "${short}" -a -- "$@")

  # set --:
  # If no arguments follow this option, then the positional parameters are unset. Otherwise, the positional parameters
  # are set to the arguments, even if some of them begin with a ‘-’.
  eval set -- "$options"

  while true; do
    case "$1" in

      -a|--all-light) will_install_all_fonts="true"; echo "all" ;shift;;
      -A|--all) will_install_all_fonts_light="true"; echo "all-light" ;shift;;
      -g|--google-light) will_install_google_fonts_light="true"; echo "google-light" ;shift;;
      -G|--google) will_install_google_fonts="true"; echo "google"; shift;;
      -n|--nerd-light) will_install_nerd_fonts_light="true"; echo "nerd-light"; shift;;
      -N|--nerd) will_install_nerd_fonts="true"; echo "nerd"; shift;;
      -p|--powerline-light) will_install_powerline_fonts_light="true"; echo "power-light" ;shift;;
      -P|--powerline) will_install_powerline_fonts="true"; echo "power"; shift;;
      -h|--help) will_install_powerline_fonts="true"; echo "help"; break;;
      -i|--interactive) menu_font_select; break;;
      *) echo "any"; break;;

    esac;
  done;
}

function main() {
  parse_options "$@"

}

main "$@"
