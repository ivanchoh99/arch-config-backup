#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

export TERM=xterm-256color
export PATH=$PATH:~/.local/bin
eval "$(oh-my-posh init bash --config ~/dotfiles/oh-my-posh/theme/mytheme.omp.json)"


# Load Angular CLI autocompletion.
source <(ng completion script)
