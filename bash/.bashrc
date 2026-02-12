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
# ~/.bashrc

# 1. Mover el PATH al principio para asegurar que esté disponible siempre
export PATH=$PATH:~/.local/bin:/usr/bin
export DOCKER_HOST=unix:///run/user/$UID/podman/podman.sock
export 

# 2. Si no es interactivo, no cargar alias/prompt, pero el PATH ya se cargó arriba
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

export TERM=xterm-256color
eval "$(oh-my-posh init bash --config ~/dotfiles/oh-my-posh/theme/mytheme.omp.json)"

# 3. Autocompletado de Angular
source <(ng completion script)

# Load Angular CLI autocompletion.
source <(ng completion script)
