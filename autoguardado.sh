#!/bin/bash

# --- CONFIGURACIÓN ---
REPO_DIR="$HOME/dotfiles"
LOG_FILE="/tmp/dotfiles_autoguardado.log"

Archivos a vigilar
FILE_NATIVE="pkglist/pkglist.txt"
FILE_AUR="pkglist/aurlist.txt"

notify() {
    if command -v notify-send >/dev/null; then
        notify-send "Dotfiles Sync" "$1" --icon=package-x-generic
    fi
}

cd "$REPO_DIR" || exit 1

# Solo si hay cambios en git
if [[ -n $(git status --porcelain) ]]; then

    git add .
    
    MSG_PARTS=""

    # 1. Detectar Cambios NATIVOS (Arch)
    # Filtramos líneas nuevas (+) en el archivo native
    new_native=$(git diff --cached -U0 "$FILE_NATIVE" | grep "^+[^+]" | sed 's/^+//' | tr '\n' ' ' | xargs)
    
    if [[ -n "$new_native" ]]; then
        MSG_PARTS="📦 Arch: $new_native"
    fi

    # 2. Detectar Cambios AUR
    # Filtramos líneas nuevas (+) en el archivo aur
    new_aur=$(git diff --cached -U0 "$FILE_AUR" | grep "^+[^+]" | sed 's/^+//' | tr '\n' ' ' | xargs)

    if [[ -n "$new_aur" ]]; then
        if [[ -n "$MSG_PARTS" ]]; then MSG_PARTS="$MSG_PARTS | "; fi
        MSG_PARTS="${MSG_PARTS}🦄 AUR: $new_aur"
    fi

    # 3. Detectar Configs (Todo lo que no sea listas de paquetes)
    # Excluimos ambos archivos de lista
    configs=$(git diff --cached --name-only | grep -vE "($FILE_NATIVE|$FILE_AUR)" | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')

    if [[ -n "$configs" ]]; then
        if [[ -n "$MSG_PARTS" ]]; then MSG_PARTS="$MSG_PARTS | "; fi
        MSG_PARTS="${MSG_PARTS}🛠️ Config: $configs"
    fi

    # Fallback por si solo hubo borrados o updates menores
    if [[ -z "$MSG_PARTS" ]]; then
        MSG_PARTS="🔄 Sync: $(date '+%Y-%m-%d %H:%M')"
    fi

    # --- COMMIT & PUSH ---
    git commit -m "$MSG_PARTS" >> "$LOG_FILE" 2>&1

    if git push >> "$LOG_FILE" 2>&1; then
        notify "✅ Guardado: $MSG_PARTS"
    else
        notify "⚠️ Error al subir (Ver log)"
    fi

fi
