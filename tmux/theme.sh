#### COLOUR

tm_icon="☀"
tm_color_active=colour82
tm_color_inactive=colour241
tm_color_feature=colour10
tm_color_music=colour10
tm_active_border_color=colour10
tm_color_batt=colour77

# separators
tm_separator_left_bold="◀"
tm_separator_left_thin="❮"
tm_separator_right_bold="▶"
tm_separator_right_thin="❯"

set -g status-left-length 32
set -g status-right-length 150
set -g status-interval 5


# default statusbar colors
# set-option -g status-bg colour0
set-option -g status-fg $tm_color_active
set-option -g status-bg default
set-option -g status-attr default

# default window title colors
set-window-option -g window-status-fg $tm_color_inactive
set-window-option -g window-status-bg default
set -g window-status-format "#I #W"

# active window title colors
set-window-option -g window-status-current-fg $tm_color_active
set-window-option -g window-status-current-bg default
set-window-option -g  window-status-current-format "#[bold]#I #W"

# pane border
set-option -g pane-border-fg $tm_color_inactive
set-option -g pane-active-border-fg $tm_active_border_color

# message text
set-option -g message-bg default
set-option -g message-fg $tm_color_active

# pane number display
set-option -g display-panes-active-colour $tm_color_active
set-option -g display-panes-colour $tm_color_inactive

# clock
set-window-option -g clock-mode-colour $tm_color_active

# PLUGINGS AND SCRIPTS

# prefix highlight options
set -g @prefix_highlight_show_copy_mode 'on'
set -g @prefix_highlight_copy_mode_attr 'fg=black,bg=yellow,bold' # default is 'fg=default,bg=yellow'

tm_spotify="#[fg=$tm_color_music]#(osascript ~/dotfiles/applescripts/spotify.scpt)"
tm_itunes="#[fg=$tm_color_music]#(osascript ~/dotfiles/applescripts/itunes.scpt)"

tm_date="#[fg=$tm_color_inactive] %l:%M %p %d %b"
tm_host="#[fg=$tm_color_feature,bold]#h"
tm_session_name="#[fg=$tm_color_feature,bold]$tm_icon #S"

tm_batt="#[fg=$tm_color_batt]#{battery_percentage}"
tm_prefix_highlight="#{prefix_highlight}"

set -g status-left $tm_session_name' '$tm_prefix_highlight' '
set -g status-right $tm_spotify' #{battery_icon} '$tm_batt' #{battery_remain} '$tm_date' '$tm_host
