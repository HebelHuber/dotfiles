# some more ls aliases

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias nano='micro'
alias duf='duf --usage-threshold="0.5,0.9"'
alias cat='batcat'
alias bat='batcat'

export FZF_DEFAULT_COMMAND='find .'
alias fzf='fzf --preview "batcat --color=always --style=numbers --line-range=:500 {}"'
alias edit='micro $(fzf)'

alias ..='cd ..'
alias ...='cd ../..'

eval $(thefuck --alias fuck)
