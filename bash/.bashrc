# ~/.bashrc

# 1. Si no es interactivo, no hacer nada
[[ $- != *i* ]] && return

# 2. Aliases y Prompt
alias ls='ls --color=auto'
alias grep='grep --color=auto'
export TERM=xterm-256color

# 3. PATH Inicial
export PATH=$PATH:~/.local/bin:$HOME/.dotnet/tools

eval "$(oh-my-posh init bash --config ~/dotfiles/oh-my-posh/theme/mytheme.omp.json)"

# 5. Java Config (La clave para tu entorno)
export JAVA_HOME=/usr/lib/jvm/default
export PATH=$JAVA_HOME/bin:$PATH

# Configuración de fnm (Node Version Manager)
eval "$(fnm env --use-on-cd)"
