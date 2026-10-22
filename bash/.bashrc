# ~/.bashrc

# Si no es interactivo, no hacer nada
[[ $- != *i* ]] && return

# Aliases y Prompt
alias ls='ls --color=auto'
alias grep='grep --color=auto'
export TERM=xterm-256color

# PATH Inicial
# Seguridad: los directorios del sistema conservan prioridad sobre los de
# usuario/gestores; así un binario colocado en ~/.local/bin no suplanta a los
# binarios del sistema.
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PATH:$PNPM_HOME" ;;
esac

# Prompt (oh-my-posh)
# Guardado: si el binario no está instalado, no se imprime "command not found"
# al arrancar la terminal.
if command -v oh-my-posh >/dev/null 2>&1; then
  eval "$(oh-my-posh init bash --config ~/dotfiles/oh-my-posh/theme/mytheme.omp.json)"
fi

# Java Config (La clave para tu entorno)
# En Arch el JDK por defecto lo elige "archlinux-java set <jdk>", que mantiene
# el symlink /usr/lib/jvm/default. JAVA_HOME solo se exporta si ese symlink
# existe (es decir, si hay un JDK instalado).
if [ -d /usr/lib/jvm/default ]; then
  export JAVA_HOME=/usr/lib/jvm/default
  case ":$PATH:" in
    *":$JAVA_HOME/bin:"*) ;;
    *) export PATH="$JAVA_HOME/bin:$PATH" ;;
  esac
fi

# Configuración de fnm (Node Version Manager)
if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd)"
fi


# Android SDK: solo se define si existe (p.ej. con Android Studio instalado).
if [ -d "$HOME/Android/Sdk" ]; then
  export ANDROID_HOME="$HOME/Android/Sdk"
fi

case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$PATH:$HOME/.local/bin" ;;
esac

# Docker/Podman: DOCKER_HOST apunta al socket rootless de podman.
# Solo se exporta si el socket existe (requiere "systemctl --user enable --now
# podman.socket"); si no, "docker" fallaría buscando un socket inexistente.
PODMAN_SOCK="$XDG_RUNTIME_DIR/podman/podman.sock"
if [ -S "$PODMAN_SOCK" ]; then
  export DOCKER_HOST="unix://$PODMAN_SOCK"
fi
unset PODMAN_SOCK


# Load Angular CLI autocompletion.
if command -v ng >/dev/null 2>&1; then
  source <(ng completion script)
fi

# >>> conda initialize >>>
# Portable: usa $HOME y solo se activa si miniconda3 existe en esta máquina
if [ -d "$HOME/miniconda3" ]; then
    __conda_setup="$('$HOME/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    else
        if [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
            . "$HOME/miniconda3/etc/profile.d/conda.sh"
        else
            export PATH="$HOME/miniconda3/bin:$PATH"
        fi
    fi
    unset __conda_setup
fi
# <<< conda initialize <<<


# SDKMAN (gestor de versiones del ecosistema JVM).
# Solo se activa si está instalado; el JDK "default" del sistema lo sigue
# gestionando archlinux-java (ver el bloque de Java más arriba).
if [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
  export SDKMAN_DIR="$HOME/.sdkman"
  source "$HOME/.sdkman/bin/sdkman-init.sh"
fi
