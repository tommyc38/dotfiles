# heavily inspired by the wonderful pure theme
# https://github.com/sindresorhus/pure

# needed to get things like current git branch
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git # You can add hg too if needed: `git hg`
zstyle ':vcs_info:git*' use-simple true
zstyle ':vcs_info:git*' max-exports 2
zstyle ':vcs_info:git*' formats ' %b' 'x%R'
zstyle ':vcs_info:git*' actionformats ' %b|%a' 'x%R'

autoload colors && colors

git_dirty() {
    # check if we're in a git repo
    command git rev-parse --is-inside-work-tree &>/dev/null || return

    # check if it's dirty
    command git diff --quiet --ignore-submodules HEAD &>/dev/null;
    if [[ $? -eq 1 ]]; then
        echo "%F{red}✗%f"
    else
        echo "%F{green}✔%f"
    fi
}

# get the status of the current branch and it's remote
# If there are changes upstream, display a ⇣
# If there are changes that have been committed but not yet pushed, display a ⇡
git_arrows() {
    # do nothing if there is no upstream configured
    command git rev-parse --abbrev-ref @'{u}' &>/dev/null || return

    local arrows=""
    local status
    arrow_status="$(command git rev-list --left-right --count HEAD...@'{u}' 2>/dev/null)"

    # do nothing if the command failed
    (( !$? )) || return

    # split on tabs
    arrow_status=(${(ps:\t:)arrow_status})
    local left=${arrow_status[1]} right=${arrow_status[2]}

    (( ${right:-0} > 0 )) && arrows+="%F{011}⇣%f"
    (( ${left:-0} > 0 )) && arrows+="%F{012}⇡%f"

    echo $arrows
}


# indicate a job (for example, vim) has been backgrounded
# If there is a job in the background, display a ✱
suspended_jobs() {
    local sj
    sj=$(jobs 2>/dev/null | tail -n 1)
    if [[ $sj == "" ]]; then
        echo ""
    else
        echo "%{$FG[208]%}✱%f"
    fi
}
# You need to set $VIRTUAL_ENV_DISABLE_PROMPT="1"
# in your .zshrc in order to turn off the activate script
# prompt update
add_venv_info () {
	local virtualenv_path="$VIRTUAL_ENV"
	if [[ -n $virtualenv_path && -n $VIRTUAL_ENV_DISABLE_PROMPT ]]; then
		echo `basename $virtualenv_path`
	fi
}

precmd() {
    vcs_info
    print -P '\n%F{141}%n%F{141} @%m%f%F{205}  %~'
}

export PROMPT='%(?.%F{205}.%F{red})`add_venv_info` ❯%f '
export RPROMPT='`git_dirty`%F{241}$vcs_info_msg_0_%f `git_arrows``suspended_jobs`'

# sources: 
#	http://www.nparikh.org/unix/prompt.php
#	http://stackoverflow.com/questions/19901044/what-is-k-f-in-oh-my-zsh-theme
#	http://code.tutsplus.com/tutorials/how-to-customize-the-command-prompt--net-20586
#	http://stackoverflow.com/questions/14987013/why-is-virtualenv-not-setting-my-terminal-prompt
#	http://zanshin.net/2013/02/02/zsh-configuration-from-the-ground-up/
#	http://www.tuxradar.com/content/z-shell-made-easy
#	http://aperiodic.net/phil/prompt/
#	http://zsh.sourceforge.net/Guide/zshguide02.html
#	http://stackoverflow.com/questions/13976472/what-does-if-x-x-do-in-bash
#	https://github.com/robbyrussell/oh-my-zsh/blob/master/themes/agnoster.zsh-theme
