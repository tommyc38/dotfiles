#!/bin/bash

# MIT License
#
# Copyright (c) 2023 Tom Conley
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

script="$(basename "$0")"
temp_dir="$(mktemp -d)"
download_directory=$temp_dir  #
font_install_dir=  # Set by the function: set_font_install_dir


# Terminal output color terminator
clear='\033[0m'

# Fonts
google_fonts_input=()
google_fonts=("Roboto" "Open Sans" "Montserrat" "Lato" "Poppins" "Roboto Condensed" "Source Sans Pro" "Roboto Mono" "Inter" \
"Oswald" "Raleway" "Noto Sans" "Ubuntu" "Roboto Slab" "Nunito Sans" "Nunito" "Playfair Display" "Merriweather" "Rubik" "PT Sans" \
"Mukta" "Kanit" "Work Sans" "Lora" "Fira Sans" "Quicksand" "Barlow" "Mulish" "Inconsolata" "Titillium Web" "PT Serif" "IBM Plex Sans" \
"Heebo" "Noto Serif" "DM Sans" "Libre Franklin" "Hind Siliguri" "Karla" "Manrope" "Josefin Sans" "Nanum Gothic" "Arimo" "Dosis" \
"Libre Baskerville" "PT Sans Narrow" "Bitter" "Source Serif Pro" "Oxygen" "Anton" "Cabin" "Source Code Pro" "Bebas Neue" "Cairo" \
"Abel" "Rajdhani" "Dancing Script" "Prompt" "Lobster" "EB Garamond" "Barlow Condensed" "Exo 2" "Maven Pro" "Pacifico" "Comfortaa" \
"Signika Negative" "Hind" "Teko" "Fjalla One" "Varela Round" "Crimson Text" "Jost" "Space Grotesk" "Arvo" "Archivo" "Merriweather Sans" \
"Abril Fatface" "Asap" "Caveat" "Assistant" "M PLUS Rounded 1c" "Slabo 27px" "Fira Sans Condensed" "Cormorant Garamond" "Public Sans" \
"Yanone Kaffeesatz" "Overpass" "Play" "Tajawal" "Righteous" "Hind Madurai" "Satisfy" "IBM Plex Mono" "Zilla Slab" "Saira Condensed" \
"Red Hat Display" "Secular One" "Catamaran" "Indie Flower" "Acme" "Questrial" "Barlow Semi Condensed" "Lilita One" "Signika" \
"Nanum Myeongjo" "Domine" "IBM Plex Serif" "Sarabun" "Exo" "Bree Serif" "Fredoka One" "Archivo Narrow" "Orbitron" "Permanent Marker" \
"Russo One" "M PLUS 1p" "Amatic SC" "Chakra Petch" "DM Serif Display" "Rowdies" "Didact Gothic" "Alegreya Sans" "Alfa Slab One" \
"IBM Plex Sans Arabic" "Vollkorn" "ABeeZee" "Baloo 2" "Cardo" "Cinzel" "Ubuntu Condensed" "Space Mono" "Archivo Black" "Frank Ruhl Libre" \
"Kalam" "Tinos" "Asap Condensed" "Changa" "Alegreya" "Zeyada" "Sora" "Martel" "Courgette" "Yantramanav" "Amiri" "Be Vietnam Pro" \
"Spectral" "Outfit" "Patua One" "Urbanist" "Yellowtail" "Crete Round" "Noticia Text" "Great Vibes" "Lobster Two" "PT Sans Caption" \
"Figtree" "Cormorant" "Alata" "Rokkitt" "Prata" "Montserrat Alternates" "Encode Sans" "Michroma" "Lexend" "Passion One" "Titan One" \
"Gruppo" "Pathway Gothic One" "Kaushan Script" "Sen" "Philosopher" "Fira Sans Extra Condensed" "Old Standard TT" "Francois One" \
"Noto Sans Display" "PT Mono" "Staatliches" "Gothic A1" "Antic Slab" "Cantarell" "Sawarabi Mincho" "Bodoni Moda" "Lexend Deca" \
"Unna" "Eczar" "Khand" "Faustina" "Sacramento" "Cookie" "Gloria Hallelujah" "Press Start 2P" "Concert One" "Macondo" "Paytone One" \
"Saira" "Gelasio" "Marcellus" "Alice" "Plus Jakarta Sans" "Chivo" "Monda" "Carter One" "Ubuntu Mono" "El Messiri" "Cuprum" \
"Creepster" "Mitr" "Josefin Slab" "Luckiest Guy" "News Cycle" "Patrick Hand" "Special Elite" "Playfair Display SC" "Advent Pro" \
"Mukta Malar" "Commissioner" "Arsenal" "Crimson Pro" "Poiret One" "Aleo" "Vidaloka" "Alegreya Sans SC" "Handlee" "Marck Script" \
"Itim" "Yeseva One" "Merienda" "Ultra" "Tenor Sans" "Mr Dafoe" "IBM Plex Sans Condensed" "Neuton" "Bangers" "Taviraj" "Allura" \
"Roboto Flex" "Mada" "Volkhov" "Shrikhand" "Ruda" "Tangerine" "Architects Daughter" "Neucha" "Antonio" "Nanum Gothic Coding" \
"Quantico" "Khula" "Ropa Sans" "Viga" "Fugaz One" "Encode Sans Condensed" "Kosugi Maru" "Amaranth" "Gudea" "DM Serif Text" \
"Oleo Script" "Parisienne" "Unbounded" "Sriracha" "Sigmar One" "Libre Caslon Text" "Sanchez" "Hammersmith One" "Playball" \
"Stint Ultra Condensed" "Alex Brush" "Red Hat Text" "Homemade Apple" "Bungee" "League Spartan" "Laila" "Rubik Mono One" \
"Nanum Pen Script" "Bad Script" "Monoton" "Baskervville" "Blinker" "Readex Pro" "Economica" "Cousine" "Castoro" "Fira Mono" \
"Cabin Condensed" "Inter Tight" "Unica One" "Audiowide" "Rock Salt" "Voltaire" "Courier Prime" "BenchNine" "Roboto Serif" "Allerta Stencil" \
"Calistoga" "Lalezar" "Pragati Narrow" "Nothing You Could Do" "Jura" "Yatra One" "Damion" "Big Shoulders Display" "Days One" \
"Share Tech Mono" "Black Ops One" "Julius Sans One" "Alef" "Electrolize" "Six Caps" "Markazi Text" "Black Han Sans" "Forum" \
"Italianno" "VT323" "Pinyon Script" "Sansita" "Kreon" "Londrina Solid" "Squada One" "Berkshire Swash" "Pangolin" "Covered By Your Grace" \
"Leckerli One" "JetBrains Mono" "Antic" "Gentium Book Basic" "Anonymous Pro" "Arapey" "Syne" "Syncopate" "Caveat Brush" "Chewy" \
"Pridi" "Koulen" "Holtwood One SC" "Glegoo" "Oranienbaum" "Palanquin Dark" "Reenie Beanie" "Saira Extra Condensed" "Cutive Mono" \
"Lemonada" "Racing Sans One" "Gochi Hand" "Boogaloo" "Lustria" "Aclonica" "Nanum Brush Script" "Cabin Sketch" "Candal" "Rye" \
"Changa One" "Amita" "Mali" "Aldrich" "Wallpoet" "Rancho" "Shadows Into Light Two" "Fredericka the Great" "Alatsi" "Charm" \
"Basic" "Knewave" "Libre Barcode 39" "Rozha One" "Julee" "Cinzel Decorative" "Mrs Saint Delafield" "Jua" "Herr Von Muellerhoff" \
"Annie Use Your Telescope" "Coda" "Bevan" "Short Stack" "DM Mono" "Fira Code" "Bowlby One SC" "Graduate" "Rammetto One" \
"Arizonia" "Contrail One" "La Belle Aurore" "Just Another Hand" "Bungee Inline" "Kristi" "Sofia" "Marcellus SC" "Darker Grotesque" \
"Cormorant Infant" "Quintessential" "Cedarville Cursive" "Niconne" "Qwigley" "Alegreya SC" "Pattaya" "Coming Soon" "Henny Penny" \
"Delius" "Bubblegum Sans" "Overlock SC" "Schoolbell" "Seaweed Script" "Petit Formal Script" "Yesteryear" "Norican" "Rochester" \
"Aladin" "Smokum" "Grand Hotel" "Kosugi" "Grandstander" "Irish Grover" "Rubik Moonrocks" "Mate SC" "Aboreto" "IM Fell English SC" \
"Tillana" "Limelight" "Patrick Hand SC" "Skranji" "Dawning of a New Day" "Waiting for the Sunrise" "Bungee Shade" "Saira Stencil One" \
"Grenze Gotisch" "Rampart One" "Cutive" "Turret Road" "Cormorant SC" "Odibee Sans" "Allan" "Euphoria Script" "Pirata One" \
"Love Ya Like A Sister" "Style Script" "UnifrakturMaguntia" "Mansalva" "Montez" "Montserrat Subrayada" "Ma Shan Zheng" "Big Shoulders Text" \
"Pompiere" "Meddon" "Silkscreen" "Ms Madi" "Megrim" "DotGothic16" "Over the Rainbow" "Raleway Dots" "Sue Ellen Francisco" "Sedgwick Ave" \
"Rouge Script" "Chelsea Market" "Oooh Baby" "Baumans" "Nerko One" "Original Surfer" "Supermercado One" "Mr De Haviland" "Oregano" "Amarante" \
"Give You Glory" "Syne Mono" "Hurricane" "Allison" "Notable" "Geo" "Ruslan Display" "Vast Shadow" "BhuTuka Expanded One" "Mountains of Christmas" \
"Prosto One" "Atma" "Major Mono Display" "Modak" "Share Tech" "Odor Mean Chey" "Kufam" "Dokdo" "Rubik Dirt"  "Ledger" "Galada" "Finger Paint" \
"Stalemate" "Shojumaru"  "Clicker Script" "Almendra" "Jomhuria" "Tomorrow" "Federo" "Sail" "Akshar" "Slackey" "Just Me Again Down Here" \
"Rubik Iso" "Reggae One" "Bilbo Swash Caps" "Hi Melody" "Walter Turncoat" "Germania One" "Freckle Face" "Crafty Girls" "Lily Script One" \
"Eater" "Beth Ellen" "Life Savers" "Cormorant Unicase" "Faster One" "Loved by the King" "Shalimar" "Corinthia" "Libre Barcode 39 Text" \
"Codystar" "Libre Barcode 128" "Vibur" "League Script" "Ephesis" "Libre Barcode 39 Extended Text" "Frijole" "Lovers Quarrel" "Londrina Outline" \
"Kranky" "Londrina Shadow" "ZCOOL KuaiLe" "Gorditas" "Birthstone" "Ruthie" "The Girl Next Door" "Comforter Brush" "Hachi Maru Pop" "Wire One" \
"Train One" "Trade Winds" "Akronim" "Mystery Quest" "Unlock" "Miniver" "Zilla Slab Highlight" "Redressed" "New Rocker" "Black And White Picture"
"Barrio" "Sancreek" "WindSong" "Engagement" "Vampiro One" "Monofett" "Princess Sofia" "Libre Barcode 128 Text" "Fascinate Inline" "Ravi Prakash"
"Jolly Lodger" "Srisakdi" "Miltonian" "Dorsa" "Hanalei" "Yomogi" "Comforter" "Barriecito" "Mrs Sheppards" "Englebert" "Nosifer" "Passions Conflict" \
"Bahiana" "Caesar Dressing" "Flavors" "Butterfly Kids" "Bungee Outline" "Zen Tokyo Zoo" "Water Brush" "Astloch" "Qahiri" "Butcherman" "Rubik 80s Fade"
"Londrina Sketch" "Neonderthaw" "Rubik Distressed" "Lacquer" "Rubik Glitch" "Inspiration" "Tourney" "Rubik Beastly" "Big Shoulders Inline Text" "Rubik Wet Paint" \
"Sree Krushnadevaraya" "Denk One"
)
google_fonts_light=("Roboto" "Oswald" "Roboto Slab" "Raleway" "Noto Serif" "Josefin Sans" "Manrope" "Karla" "PT Sans Narrow" "Libre Baskerville" \
"Anton" "Cabin" "Source Code Pro" "Bebas Neue" "Cairo" "Dancing Script" "Abel" "Rajdhani" "Lobster" "Prompt" "Barlow Condensed" \
"Pacifico" "Comfortaa" "Teko" "Signika Negative" "Fjalla One" "Hind" "Crimson Text" "Space Grotesk" "JetBrains Mono" "Abril Fatface" \
"Asap" "Caveat" "Shadows Into Light" "Fira Sans Condensed" "Yanone Kaffeesatz" "Righteous" "Overpass" "Satisfy" "IBM Plex Mono" \
"Zilla Slab" "Secular One" "Catamaran" "Indie Flower" "Acme" "Lilita One" "Archivo Narrow" "Fredoka One" "Permanent Marker" "Russo One" \
"Amatic SC" "Rowdies" "Alfa Slab One" "IBM Plex Sans Arabic" "Cardo" "Cinzel" "Ubuntu Condensed" "Space Mono" "Frank Ruhl Libre" \
"Kalam" "Zeyada" "Sora" "Courgette" "Amiri" "Be Vietnam Pro" "Spectral" "Yellowtail" "Great Vibes" "Lobster Two" "Prata" "Passion One" \
"Titan One" "Gruppo" "Francois One" "Staatliches" "Antic Slab" "Sacramento" "Cookie" "Gloria Hallelujah" "Press Start 2P" "Concert One" \
"Macondo" "Alice" "Carter One" "Ubuntu Mono" "Creepster" "Luckiest Guy" "Josefin Slab" "Mitr" "Special Elite" "Playfair Display SC" \
"Advent Pro" "Poiret One" "Aleo" "Vidaloka" "Handlee" "Ultra" "Mr Dafoe" "Bangers" "Allura" "Shrikhand" "Volkhov" "Tangerine" "Viga" \
"Fugaz One" "Oleo Script" "Parisienne" "Sigmar One" "Sanchez" "Hammersmith One" "Playball" "Alex Brush" "Bungee" "Homemade Apple" \
"Rubik Mono One" "Nanum Pen Script" "League Spartan" "Laila" "Monoton" "Bad Script" "Economica" "Rock Salt" "Allerta Stencil" \
"Courier Prime" "BenchNine" "Lalezar" "Nothing You Could Do" "Damion" "Share Tech Mono" "Black Ops One" "Julius Sans One" "Six Caps" "Italianno"
"VT323" "Londrina Solid" "Berkshire Swash" "Covered By Your Grace" "Syne" "Syncopate" "Chewy" "Caveat Brush" "Koulen" "Reenie Beanie" \
"Gochi Hand" "Cabin Sketch" "Rye" "Candal" "Cantata One" "Mali" "Rancho" "Wallpoet" "Fredericka the Great" "Alatsi" "Mrs Saint Delafield" \
"Julee" "Cinzel Decorative" "Jua" "Just Another Hand" "Bungee Inline" "La Belle Aurore" "Kristi" "Cedarville Cursive" "Qwigley"  "Henny Penny" \
"Bubblegum Sans" "Amiko" "Overlock SC" "Schoolbell" "Yesteryear" "Smokum" "Kosugi" "Grandstander" "Irish Grover" "Rubik Moonrocks" \
"Noto Serif Display" "Stardos Stencil" "Skranji" "Vollkorn SC" "Share" "Waiting for the Sunrise" "Bungee Shade" "Grenze Gotisch" "Montez"
"Raleway Dots" "Chelsea Market" "Sue Ellen Francisco" "Notable" "Ruslan Display" "Vast Shadow" "Mountains of Christmas" "Slackey" "Eater" \
"Faster One" "Loved by the King" "Codystar" "Unkempt" "Ranchers" "UnifrakturCook" "Frijole" "Sree Krushnadevaraya" "Londrina Outline" "Londrina Shadow" \
"Ruthie" "Train One" "Potta One" "Denk One" "Trade Winds" "Mystery Quest" "New Rocker" "Black And White Picture" "Barrio" "Monofett" "Bigelow Rules" \
"Comforter" "Joti One" "Barriecito" "Englebert" "Nosifer" "Bahiana" "Caesar Dressing" "Bungee Outline" "Butcherman" "Rubik 80s Fade"
)

powerline_fonts_input=()
powerline_fonts=("3270" "AnonymousPro" "Arimo" "Cousine" "D2Coding" "DejaVuSansMono" "DroidSansMono" "DroidSansMonoDotted" "DroidSansMonoSlashed"
  "FiraMono" "GoMono" "Hack" "Inconsolata-g" "Inconsolata" "InconsolataDz" "InputMono" "LiberationMono" "Meslo Dotted" "Meslo Slashed" "Monofur"
  "NotoMono" "NovaMono" "ProFont" "RobotoMono" "SourceCodePro" "SpaceMono" "SymbolNeu" "Terminus" "Tinos" "UbuntuMono")
powerline_fonts_light=("Hack" "DroidSansMono" "RobotoMono" "UbuntuMono")

nerd_fonts_input=()
nerd_fonts=("3270" "Agave" "AnonymousPro" "Arimo" "AurulentSansMono" "BigBlueTerminal" "BitstreamVeraSansMono" "CascadiaCode" "CodeNewRoman" "Cousine"
  "DaddyTimeMono.zip" "DejaVuSansMono.zip" "DroidSansMono" "FantasqueSansMono" "FiraCode" "FiraMono" "FontPatcher" "Go-Mono" "Gohu" "Hack" "Hasklig.zip"
  "HeavyData" "Hermit" "iA-Writer" "IBMPlexMono" "Inconsolata" "InconsolataGo" "InconsolataLGC" "Iosevka" "JetBrainsMono" "Lekton" "LiberationMono"
  "Lilex" "Meslo" "Monofur" "Monoid" "Mononoki" "MPlus" "NerdFontsSymbolsOnly" "Noto" "OpenDyslexic" "Overpass" "ProFont" "ProggyClean" "RobotoMono"
  "ShareTechMono" "SourceCodePro" "SpaceMono" "Terminus" "Tinos" "Ubuntu" "UbuntuMono" "VictorMono")

nerd_fonts_light=("Hack" "DroidSansMono" "RobotoMono" "JetBrainsMono" "UbuntuMono")

# Font download urls
google_fonts_url="https://fonts.google.com/download?family="
nerd_fonts_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/" # Check and update to the most recent version
powerline_fonts_url="https://github.com/powerline/fonts.git"

# See options
download_only=
install_only=

# Fonts to install (either empty or "true")
install_google_fonts=
install_google_fonts_light=
install_nerd_fonts=
install_nerd_fonts_light=
install_powerline_fonts=
install_powerline_fonts_light=

# Create a directory if one doesn't exist.
function make_dir() {
  local directory="$1"
  if [ ! -d "$directory" ]; then
    mkdir -p "$directory"
  fi
}

# Download and extract zip files.
function download() {
  local download_url="${1// /%20}"
  local download_dir="$2"
  local target_dir="$3"
  local download_file="$4"

  make_dir "$download_dir"

  if [ ! -f "$download_dir/$download_file" ]; then
    echo "Downloading $download_url as $download_file"
    if ! curl -L -o "$download_dir/$download_file" "$download_url"; then
      echo "$(color_red "Failed to download $download_file")"
      exit 1
    fi
  else
    echo "$download_file has already downloaded."
  fi

  if [[ $download_file =~ .zip$   ]]; then
    make_dir "$target_dir"
    if [ -n "$(ls -A "$target_dir")" ]; then
      echo "Already Extracted $download_file"
    else
      if ! unzip "$download_dir/$download_file" -d "$target_dir" &> /dev/null; then
        echo "$(color_red "Failed to extract $download_file")"
        exit 1
      fi
      echo "Extracted $download_file to $target_dir"
    fi

  fi

  # Nerd Fonts has Windows compatible fonts which we don't need.
  if [ -n "$(ls "$target_dir" | grep "Windows Compatible.ttf$")" ]; then
    find "$target_dir" -name "*Windows Compatible.ttf" -exec rm {} \;
  fi

}

# Clone a repository.
function clone_repo() {
  local download_url="$1"
  local target_dir="$2"
  # if an argument is given it is used to select which fonts to install
  if [ ! -d "$target_dir" ]; then
    echo "Cloning $download_url into $target_dir"
    if ! git clone  "$download_url" "$target_dir" --depth=1; then
      echo "$(color_red "Failed to clone $download_url")"
      echo "Failed to download $1"
      exit 1
    fi
  else
    echo "$download_url has already been cloned."
  fi

}

# Check if a supplied font exists in one of the font arrays.
function check_value_in_array() {

  local font="$1"
  local subset_array=
  local array=
  if [ "$font" == "google" ]; then
    subset_array=("${google_fonts_input[@]}")
    array=("${google_fonts[@]}")
  elif [ "$font" == "nerd" ]; then
    subset_array=("${nerd_fonts_input[@]}")
    array=("${nerd_fonts[@]}")
  elif [ "$font" == "powerline" ]; then
    subset_array=("${powerline_fonts_input[@]}")
    array=("${powerline_fonts[@]}")
  else
    echo "fail"
    return
  fi

  local values=
  local match=

  for sub_value in "${subset_array[@]}"; do
    for value in "${array[@]}"; do
      if [ "$sub_value" == "$value" ]; then
        match="true"
      fi
    done
    if [ -z "$match" ]; then
      values+="$sub_value, "
    fi
    match=
  done

  echo "${values}" | sed 's/, $//g'
}

# For longer lists it's easier to read when they are displayed in columns.
# Many thanks to https://github.com/loiccattani/Columnize for this awesome function!
function columnize() {
  local values=("$@")
  local term_width
  local longest_value=0
  local curr_col=0

  # Find the longest value
  for value in "${values[@]}"; do
    if [[ "${#value}" -gt "$longest_value" ]]; then
      longest_value="${#value}"
    fi
  done

  # Compute column span
  term_width=$(tput cols)
  ((columns = term_width / (longest_value + 2)))

  # Print values with pretty column width
  for value in "${values[@]}"; do
    local value_len="${#value}"
    echo -n "$value"
    ((spaces_missing = longest_value - value_len + 2))
    printf "%*s" "$spaces_missing"
    ((curr_col++))
    if [[ $curr_col == "$columns" ]]; then
      echo
      curr_col=0
    fi
  done

  # Make sure there is a newline at the end
  if [[ $curr_col != 0 ]]; then
    echo
  fi
}

# Install fonts.
function install_fonts() {
  if [ -n "$install_google_fonts_light" ] || [ -n "$install_google_fonts" ] || [ ${#google_fonts_input[*]} != "0" ]; then
     local google_font_array
     [ -n "$install_google_fonts" ] && google_font_array=("${google_fonts[@]}")
     [ -n "$install_google_fonts_light" ] && google_font_array=("${google_fonts_light[@]}")
     [ "${#google_fonts_input[@]}" != "0" ] && google_font_array=("${google_fonts_input[@]}")
     local total_google_fonts=${#google_font_array[@]}
     local google_install_count=0

    if [ -z "$install_only" ]; then
      echo "Downloading Google Fonts..."
      for google_font in "${google_font_array[@]}"; do
        download "$google_fonts_url$google_font" "$google_fonts_download_dir/zip-files" \
         "$google_fonts_download_dir/$google_font" "$google_font.zip"
      done
      echo "Downloading Google Fonts Done!"
    fi
    if [ -z "$download_only" ]; then
      echo "Installing Google Fonts..."
      for google_font in "${google_font_array[@]}"; do
         if [ -d "$google_fonts_download_dir/$google_font" ]; then
            find "$google_fonts_download_dir/$google_font" -name "*.[ot]tf" -type f -exec  cp {} "$font_install_dir" \;
            ((google_install_count++))
            echo -e "$(color_green "Google Fonts ($google_install_count/$total_google_fonts): $google_font installed ✔")"
            ls "$google_fonts_download_dir/$google_font" | grep '[ot]tf$' | sed 's/^/  /g'
         fi
      done
      echo "Installing Google Fonts Done!"
    fi
  fi

  if [ -n "$install_nerd_fonts_light" ] || [ -n "$install_nerd_fonts" ] || [ ${#nerd_fonts_input[*]} != "0" ]; then
     local nerd_font_array
     [ -n "$install_nerd_fonts" ] && nerd_font_array=("${nerd_fonts[@]}")
     [ -n "$install_nerd_fonts_light" ] && nerd_font_array=("${nerd_fonts_light[@]}")
     [ "${#nerd_fonts_input[@]}" != "0" ] && nerd_font_array=("${nerd_fonts_input[@]}")
     local total_nerd_fonts=${#nerd_font_array[@]}
     local nerd_install_count=0

     if [ -z "$install_only" ]; then
        echo "Downloading Nerd Fonts..."
        for nerd_font in "${nerd_font_array[@]}"; do
           download "$nerd_fonts_url$nerd_font.zip" "$nerd_fonts_download_dir/zip-files" \
           "$nerd_fonts_download_dir/$nerd_font" "$nerd_font.zip"
        done
        echo "Downloading Nerd Fonts Done!"
     fi

    if [ -z "$download_only" ]; then
      echo "Installing Nerd Fonts..."
       for nerd_font in "${nerd_font_array[@]}"; do
         if [ -d "$nerd_fonts_download_dir/$nerd_font" ]; then
            find "$nerd_fonts_download_dir/$nerd_font" -name "*.[ot]tf" -type f -exec cp {} "$font_install_dir" \;
            ((nerd_install_count++))
            echo -e "$(color_green "Nerd Fonts ($nerd_install_count/$total_nerd_fonts): $nerd_font installed ✔")"
            ls "$nerd_fonts_download_dir/$nerd_font" -I "*Windows Compatible*" | grep '[ot]tf$' | sed 's/^/  /g'
         fi
      done
      echo "Installing Nerd Fonts Done!"
    fi
  fi

  if [ -n "$install_powerline_fonts_light" ] || [ -n "$install_powerline_fonts" ] || [ ${#powerline_fonts_input[*]} != "0" ]; then
     local powerline_font_array
     [ -n "$install_powerline_fonts" ] && powerline_font_array=("${powerline_fonts[@]}")
     [ -n "$install_powerline_fonts_light" ] && powerline_font_array=("${powerline_fonts_light[@]}")
     [ "${#powerline_fonts_input[@]}" != "0" ] && powerline_font_array=("${powerline_fonts_input[@]}")
     local total_powerline_fonts=${#powerline_font_array[@]}
     local powerline_install_count=0

     if [ -z "$install_only" ]; then
       echo "Downloading Powerline Fonts.."
       clone_repo "$powerline_fonts_url" "$powerline_fonts_download_dir"
       echo "Downloading Powerline Fonts Done!"
     fi

     if [ -z "$download_only" ]; then
       echo "Installing Powerline Fonts.."
       for powerline_font in "${powerline_font_array[@]}"; do
         if [ -d "$powerline_fonts_download_dir/$powerline_font" ]; then
          find "$powerline_fonts_download_dir/$powerline_font" \( -name "$powerline_font*.[ot]tf" -or -name "$powerline_font*.pcf.gz" \) -type f -print0 \ | xargs -0 -n1 -I % cp "%" "$font_install_dir/"
          ((powerline_install_count++))
          echo -e "$(color_green "Powerline Fonts ($powerline_install_count/$total_powerline_fonts): $powerline_font installed ✔")"
          ls "$powerline_fonts_download_dir/$powerline_font" | grep '[ot]tf$' | sed 's/^/  /g'
         fi
       done
       echo "Installing Powerline Fonts Done!"
    fi
  fi
}

# Set the font installation directory.
function set_font_install_dir() {
  local font_system_dir=
  local font_user_dir=
  local use_user_dir="$1"

  if test "$(uname)" = "Darwin"; then
    # MacOS
    font_system_dir="/Library/Fonts"
    font_user_dir="$HOME/Library/Fonts"
  else
    # Linux
    font_system_dir="/usr/local/share/fonts"
    font_user_dir="$HOME/.fonts"
  fi
  if [ -n "$use_user_dir" ]; then
    if [ ! -d "$font_user_dir" ] && [ "$(uname)" != "Darwin" ]; then
      mkdir -p "$font_user_dir"
    fi
    font_install_dir="$font_user_dir"
  else
    font_install_dir="$font_system_dir"
  fi
}

# Turn message output green.
function color_green() {
  local color_green="\033[0;32m"
  echo -e "$color_green$1$clear"
}

# Turn message output red.
function color_red() {
  local color_red='\033[0;31m'
  echo -ne $color_red$1$clear
}

# Check the supplied download path.
function handle_download_path_arg(){
  local absolute_path
  absolute_path="$(readlink -f "$1")"
  if [ ! -d "$absolute_path" ]; then
    echo "$absolute_path doesn't exist!. A directory supplied to -d|--download-directory must exist. See usage: fonts.sh --help"
    exit 1
  fi
  echo "$absolute_path"
  download_directory="$absolute_path"
}

# Create messages when supplied fonts are invalid.
function handle_invalid_fonts(){
  local font="$1"
  local invalid_fonts="$2"
  local name
  [ "$font" == "google" ] && name="Google"
  [ "$font" == "nerd" ] && name="Nerd"
  [ "$font" == "powerline" ] && name="Powerline"

  echo -e "Invalid $name Fonts:\n  $(color_red "$invalid_fonts")"
  echo "To see valid options run: fonts --list-$name-fonts"
  echo "See usage: fonts.sh --help"
  exit 1
}

# Display usage.
function usage() {
  local help="
Usage:
  $script [-G|--google-fonts] [-g|--google-fonts-light] [--google-fonts-select '<font>, ...'] [--list-google-fonts]
  [--list-google-fonts-light] [-N|--nerd-fonts] [-n|--nerd-fonts-light] [--nerd-fonts-select '<font>, ...']
  [--list-nerd-fonts] [--list-nerd-fonts-light] [-P|--powerline-fonts] [-p|--powerline-fonts-light]
  [--powerline-fonts-select '<font>, ...'] [--list-powerline-fonts] [--list-powerline-fonts -light] [-I|--install-only]
  [-D|--download-only] [-d|--download-directory <dir>] [-h|--help] [-u|--user]

Description:
  Download and install Google Fonts, Nerd Fonts, and Powerline Fonts to either your user or system directory. Note, not
  all Google Fonts are included, only a curated list of the most popular Google Fonts (580+).  To see which fonts will
  be installed with a given option see the --list options. If you want to install fewer fonts, see install options with a
  'light' suffix. Note, these are font families which may or may not include multiple types (e.g. regular, bold, etc.).

Options:
  -d, --download-directory <dir>  Download fonts to the supplied directory (relative or absolute). If this option is not
                                  selected the files are downloaded to a temporary directory.
  -I, --install-only              Only install fonts. The [-d|--download-directory] option is required with this option.
                                  Also, you must include the same install options or the script won't know where to look.
                                  See examples.
  -D, --download-only             Only download fonts. The [-d|--download-directory] option is required with this option.
  -G, --google-fonts              Install all Google Fonts.
  -g, --google-fonts-light        Install a smaller subset of Google Fonts.
  -N, --nerd-fonts                Install all Nerd Fonts.
  -n, --nerd-fonts-light          Install a smaller subset of Nerd Fonts.
  -P, --powerline-fonts           Install all Powerline Fonts.
  -p, --powerline-fonts-light     Install a smaller subset of Powerline Fonts.
  -u, --user                      Install fonts into the user font directory (system is the default).
  -h, --help                      Show usage.

  --google-fonts-select '<font>, ...'     A custom list of Google Fonts to install. See usage below.
  --nerd-fonts-select '<font>, ...'       A custom list of Nerd Fonts to install. See usage below.
  --powerline-fonts-select '<font>, ...'  A custom list of Powerline Fonts to install. See usage below.
  --list-google-fonts                     List all Google Fonts that will be installed.
  --list-google-fonts-light               List a subset of Google Fonts that will be installed.
  --list-nerd-fonts                       List all Nerd Fonts that will be installed.
  --list-nerd-fonts-light                 List a subset of Nerd Fonts that will be installed.
  --list-powerline-fonts                  List all Powerline Fonts that will be installed.
  --list-powerline-fonts-light            List a subset of Powerline Fonts that will be installed.

Examples:
  Correct:
    $script --google-fonts --nerd-fonts --powerline-fonts                           # Install all fonts
    $script --google-fonts-light --nerd-fonts --powerline-fonts-light               # Install fonts
    $script --list-google-fonts --list-nerd-fonts --list-powerline-fonts            # List all fonts
    $script --list-google-fonts --list-nerd fonts-light                             # List fonts

  Wrong:
    $script --google-fonts --google-fonts-light  # only one selection from a given font group can be installed.

  For finer grain control (e.g. manually remove bold fonts, etc.), you can use these options together as follows:

  Correct:
    1.) $script --download-only --download-directory=\"path/to/dir\" --google-fonts --nerd-fonts-light
    2.) Manually remove fonts.
    3.) $script --install-only --download-directory=\"path/to/dir\" --google-fonts --nerd-fonts-light

    ** When using the --install-only option, it will only look in expected directories based on the font install
    options. If you add folders with fonts that don't match download_directory/font_name of a font in a given --list
    then it won't be installed.  If you manually want to add fonts just add them to any directory the script
    expects to find the fonts in (e.g. a directory the script downloaded a font to - download_dir/font-group/font).

  Wrong:
    1.) $script --download-only --download-directory=\"path/to/dir\" --google-fonts --nerd-fonts-light
    2.) Manually remove fonts.
    3.) $script --install-only --download-directory=\"path/to/dir\"
        $script --install-only --download-directory=\"path/to/dir\" --powerline-fonts

  Selected fonts must be included in one the respective font lists and must be delimited by either ', ' or ',' with
  no line breaks.

  Correct:
    $script --google-fonts-select='Roboto, Denk One, Mystery Quest, New Rocker, Luckiest Guy'

    local fonts='Roboto, Denk One, Mystery Quest, New Rocker \\
    Aladin, Smokum, Grand Hotel, Kosugi, Grandstander, Irish Grover'

    $script --google-fonts-select=\"\$fonts\"

  Wrong:
    $script --google-fonts-select 'Roboto' 'Denk One' 'Mystery Quest' 'New Rocker' 'Luckiest Guy'

    local fonts='Roboto, Denk One, Mystery Quest, New Rocker \\n
    Aladin, Smokum, Grand Hotel, Kosugi, Grandstander, Irish Grover'

    $script --google-fonts-select=\"\$fonts\""
  echo "$help"
}


# Parse the script args.
function parse_options() {
  local short="gGnNpPhuDId:"
  local long="google-fonts,google-fonts-light,nerd-fonts,nerd-fonts-light,powerline-fonts,powerline-fonts-light,
  list-google-fonts,list-nerd-fonts,list-powerline-fonts,list-google-fonts-light,list-nerd-fonts-light,list-powerline-fonts-light,
  help,user,download-directory:,download-only,install-only,google-fonts-select:,powerline-fonts-select:,nerd-fonts-select:"

  local options
  local list_google_fonts=
  local list_nerd_fonts=
  local list_powerline_fonts=
  local list_google_fonts_light=
  local list_nerd_fonts_light=
  local list_powerline_fonts_light=
  local download_dir_supplied=
  local use_user_dir=

  if [ "$(uname)" == "Darwin" ]; then
    if [ -e "/usr/local/opt/gnu-getopt/bin/getopt" ]; then
      options=$(/usr/local/opt/gnu-getopt/bin/getopt -l "$long" -o "$short" -- "$@")
    else
      echo "This script requires the latest getopt command. Upgrade with:"
      echo "  brew install gnu-getopt"
      exit 1
    fi
  else
      options=$(getopt -l "$long" -o "$short" -a -- "$@")
  fi

  eval set -- "$options"

  while true; do
    case "$1" in

      -g | --google-fonts-light) install_google_fonts_light="true"; shift ;;
      -G | --google-fonts) install_google_fonts="true"; shift ;;
      --list-google-fonts) list_google_fonts="true"; shift ;;
      --list-google-fonts-light) list_google_fonts_light="true"; shift ;;
      --google-fonts-select) shift
        # IFS can only parse single characters. We need to convert ', ' to ','
        IFS="," read -r -a google_fonts_input <<< "${1//, /,}"
        local invalid_fonts
        invalid_fonts="$(check_value_in_array "google")"
        if [ -n "$invalid_fonts" ]; then
          handle_invalid_fonts "google" "$invalid_fonts"
        fi
        shift;;
      -n | --nerd-fonts-light) install_nerd_fonts_light="true"; shift ;;
      -N | --nerd-fonts) install_nerd_fonts="true"; shift ;;
      --list-nerd-fonts) list_nerd_fonts="true"; shift ;;
      --list-nerd-fonts-light) list_nerd_fonts_light="true"; shift ;;
      --nerd-fonts-select) shift;
        # IFS can only parse single characters. We need to convert ', ' to ','
        IFS="," read -r -a nerd_fonts_input <<< "${1//, /,}"
        echo ""
        local invalid_fonts
        invalid_fonts="$(check_value_in_array "nerd")"
        if [ -n "$invalid_fonts" ]; then
          handle_invalid_fonts "nerd" "$invalid_fonts"
        fi
        shift;;
      -p | --powerline-fonts-light) install_powerline_fonts_light="true"; shift ;;
      -P | --powerline-fonts) install_powerline_fonts="true"; shift ;;
      --list-powerline-fonts) list_powerline_fonts="true"; shift ;;
      --list-powerline-fonts-light) list_powerline_fonts_light="true"; shift ;;
      --powerline-fonts-select) shift;
        # IFS can only parse single characters. We need to convert ', ' to ','
        IFS="," read -r -a powerline_fonts_input <<< "${1//, /,}"
        local invalid_fonts
        invalid_fonts="$(check_value_in_array "powerline")"
        if [ -n "$invalid_fonts" ]; then
          handle_invalid_fonts "powerline" "$invalid_fonts"
        fi
        shift;;
      -I | --install-only) install_only="true"; shift;;
      -D | --download-only) download_only="true"; shift;;
      -d | --download-directory) shift
        handle_download_path_arg "$1"
        download_dir_supplied="true"
        shift;;
      -u | --user) use_user_dir="true"; shift ;;
      -h|--help) usage; exit 0 ;;
      --) break;;
      *) usage; exit 0 ;;

    esac
  done

  # Font download directories
  google_fonts_download_dir="${download_directory}/google"
  nerd_fonts_download_dir="${download_directory}/nerd"
  powerline_fonts_download_dir="${download_directory}/powerline"

  # Check both --download-only and --install-only aren't both selected
  if [ -n "$install_only"  ] && [ -n "$download_only" ]; then
    echo "You can't have both -d|--download-only-to AND -i|--install-only-from options at the same time."
    echo "See usage: $0 --help"
    exit 1
  fi
  # Check we have a supplied download directory.
  if [ -n "$install_only"  ] && [ -z "$download_dir_supplied" ]; then
    echo "The option -I|--install-only must include the download directory -d|--download-directory."
    echo "See usage: $0 --help"
    exit 1
  fi

  # Check we have a supplied download directory.
  if [ -n "$download_only"  ] && [ -z "$download_dir_supplied" ]; then
    echo "The option -D|--download-only must include the download directory -d|--download-directory."
    echo "See usage: $0 --help"
    exit 1
  fi

  # List fonts.
  if [ -n "$list_google_fonts" ] || [ -n "$list_nerd_fonts" ] || [ -n "$list_powerline_fonts" ] \
    || [ -n "$list_google_fonts_light" ] || [ -n "$list_nerd_fonts_light" ] || [ -n "$list_powerline_fonts_light" ]; then

    [ -n "$list_google_fonts" ] && echo -e "Google Fonts (${#google_fonts[@]}):\n$(columnize "${google_fonts[@]}")\n"
    [ -n "$list_nerd_fonts" ] && echo -e "Nerd Fonts (${#nerd_fonts[@]}):\n$(columnize "${nerd_fonts[@]}")\n"
    [ -n "$list_powerline_fonts" ] && echo -e "Powerline Fonts (${#powerline_fonts[@]}):\n$(columnize "${powerline_fonts[@]}")\n"

    [ -n "$list_google_fonts_light" ] && echo -e "Google Fonts Light (${#google_fonts_light[@]}):\n$(columnize "${google_fonts_light[@]}")\n"
    [ -n "$list_nerd_fonts_light" ] && echo -e "Nerd Fonts Light (${#nerd_fonts_light[@]}):\n$(columnize "${nerd_fonts_light[@]}")\n"
    [ -n "$list_powerline_fonts_light" ] && echo -e "Powerline Light (${#google_fonts_light[@]}):\n$(columnize "${powerline_fonts_light[@]}")\n"
    exit 0
  fi

  # Check Google install options.
  if [ -n "$install_google_fonts" ] || [ -n "$install_google_fonts_light" ] || [ ${#google_fonts_input[*]} != "0" ]; then
    if { [ -n "$install_google_fonts" ] && [ -n "$install_google_fonts_light" ] && [ ${#google_fonts_input[*]} != "0" ]; } \
       || { [ -n "$install_google_fonts" ] && [ -n "$install_google_fonts_light" ]; } \
       || { [ -n "$install_google_fonts" ] && [ ${#google_fonts_input[*]} != "0" ]; } \
       || { [ -n "$install_google_fonts_light" ] && [ ${#google_fonts_input[*]} != "0" ]; }; then
        echo "Only one Google Font install option can be chosen: --google-fonts, --google-fonts-light, or --google-fonts-select"
        echo "See usage: $0 --help"
        exit 1
    fi
  fi

  # Check Nerd Fonts install options.
  if [ -n "$install_nerd_fonts" ] || [ -n "$install_nerd_fonts_light" ] || [ ${#nerd_fonts_input[*]} != "0" ]; then
    if { [ -n "$install_nerd_fonts" ] && [ -n "$install_nerd_fonts_light" ] && [ ${#nerd_fonts_input[*]} != "0" ]; } \
      || { [ -n "$install_nerd_fonts" ] && [ -n "$install_nerd_fonts_light" ]; } \
      || { [ -n "$install_nerd_fonts" ] && [ ${#nerd_fonts_input[*]} != "0" ]; } \
      || { [ -n "$install_nerd_fonts_light" ] && [ ${#nerd_fonts_input[*]} != "0" ]; }; then
        echo "Only one Nerd Font install option can be chosen: --nerd-fonts, --nerd-fonts-light, or --nerd-fonts-select"
        echo "See usage: $0 --help"
        exit 1
    fi
  fi

  # Check Powerline install options.
  if [ -n "$install_powerline_fonts" ] || [ -n "$install_powerline_fonts_light" ] || [ ${#powerline_fonts_input[*]} != "0" ]; then
    if { [ -n "$install_powerline_fonts" ] && [ -n "$install_powerline_fonts_light" ] && [ ${#powerline_fonts_input[*]} != "0" ]; } \
     || { [ -n "$install_powerline_fonts" ] && [ -n "$install_powerline_fonts_light" ]; } \
     || { [ -n "$install_powerline_fonts" ] && [ ${#powerline_fonts_input[*]} != "0" ]; } \
     || { [ -n "$install_powerline_fonts_light" ] && [ ${#powerline_fonts_input[*]} != "0" ]; }; then
        echo "Only one Powerline install option can be chosen: --powerline-fonts, --powerline-fonts-light, or --powerline-fonts-select"
        echo "See usage: $0 --help"
        exit 1
    fi
  fi

  # Check download-only and install-only options.
  if { [ -z "$install_google_fonts" ] && [ -z "$install_google_fonts_light" ] && [ ${#google_fonts_input[*]} == "0" ] && \
       [ -z "$install_nerd_fonts" ] && [ -z "$install_nerd_fonts_light" ] && [ ${#nerd_fonts_input[*]} == "0" ] && \
       [ -z "$install_powerline_fonts" ] && [ -z "$install_powerline_fonts_light" ] && [ ${#powerline_fonts_input[*]} == "0" ]; } &&
       { [ -n "$install_only" ] ||  [ -n "$download_only" ]; } ; then
        echo "You must select font install group(s) (e.g. --google-fonts) with either -d|--download-only OR -i|--install-only"
        echo "See usage: $0 --help"
        exit 1
  fi

  # Set the installation directory.
  if [ -n "$use_user_dir" ]; then
    set_font_install_dir "$use_user_dir"
  else
    set_font_install_dir
  fi
}

# The main script entrypoint.
function main() {
  parse_options "$@"
  install_fonts
}

main "$@"
