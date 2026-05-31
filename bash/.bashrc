# ~/.bashrc

# Si no es interactivo, no hacer nada
[[ $- != *i* ]] && return

# Aliases y Prompt
alias ls='ls --color=auto'
alias grep='grep --color=auto'
export TERM=xterm-256color

# PATH Inicial
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"

eval "$(oh-my-posh init bash --config ~/dotfiles/oh-my-posh/theme/mytheme.omp.json)"

# Java Config (La clave para tu entorno)
export JAVA_HOME=/usr/lib/jvm/default
export PATH=$JAVA_HOME/bin:$PATH

# Configuración de fnm (Node Version Manager)
eval "$(fnm env --use-on-cd)"


# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

export ANDROID_HOME=$HOME/Android/Sdk
export PATH="$HOME/.local/bin:$PATH"
export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/podman/podman.sock


# Load Angular CLI autocompletion.
source <(ng completion script)

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/dcloud99/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/dcloud99/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/dcloud99/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/dcloud99/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

