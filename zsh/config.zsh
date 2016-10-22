setopt NO_BG_NICE
setopt NO_HUP
setopt NO_LIST_BEEP
setopt LOCAL_OPTIONS
setopt LOCAL_TRAPS
#setopt IGNORE_EOF
setopt PROMPT_SUBST

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# history
setopt HIST_VERIFY
setopt EXTENDED_HISTORY
setopt HIST_REDUCE_BLANKS
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt INC_APPEND_HISTORY SHARE_HISTORY
setopt APPEND_HISTORY

setopt COMPLETE_ALIASES

# keybindings in the command prompt
#
bindkey -v
# http://stackoverflow.com/questions/18042685/list-of-zsh-bindkey-commands
# http://www.cs.elte.hu/zsh-manual/zsh_14.html#SEC47
# https://github.com/zsh-users/zsh-autosuggestions/blob/master/src/config.zsh
# Quick Ref:
#
# bindkey -l            lists <keymap> names
# bindkey -M <keymap>   lists keymappings
#
# ESC SPACE: vi-forward-char

fpath=($ZSH/functions $fpath)
# autoload -U $ZSH/functions/*(:t)
