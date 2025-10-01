if [[ -x "/opt/homebrew/bin/brew" ]]; then
  BREW_PREFIX="/opt/homebrew"
else
  BREW_PREFIX="/usr/local"
fi
echo "The shell you are using is: $BREW_PREFIX"
[ -z "$(cat < /etc/shells | grep "${BREW_PREFIX}/bin/bash")" ] && echo "${BREW_PREFIX}/bin/bash" >> /etc/shells
[ -z "$(cat < /etc/shells | grep "${BREW_PREFIX}/bin/zsh")" ] && echo "${BREW_PREFIX}/bin/zsh" >> /etc/shells
# Because this script is ran with sudo we need to apply it to the user running the sudo command.
chsh -s "${BREW_PREFIX}/bin/zsh" "$SUDO_USER"
