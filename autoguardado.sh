#!/bin/bash

# --- CONFIGURACIÓN ---
REPO_DIR="$HOME/dotfiles"
LOG_FILE="/tmp/dotfiles_autoguardado.log"

# Archivos a vigilar
FILE_NATIVE="pkglist/pkglist.txt"
FILE_AUR="pkglist/aurlist.txt"

notify() {
    if command -v notify-send >/dev/null; then
        notify-send "Dotfiles Sync" "$1" --icon=package-x-generic
    fi
}

cd "$REPO_DIR" || exit 1

# Usamos -A para asegurar que Git registre archivos eliminados físicamente
git add -A

# Solo si hay cambios en git
if [[ -n $(git status --porcelain) ]]; then

    MSG_PARTS=""

    # --- 1. CAMBIOS NATIVOS (Arch) ---
    new_native=$(git diff --cached -U0 "$FILE_NATIVE" | grep "^+[^+]" | sed 's/^+//' | tr '\n' ' ' | xargs)
    del_native=$(git diff --cached -U0 "$FILE_NATIVE" | grep "^-[^-]" | sed 's/^-//' | tr '\n' ' ' | xargs)

    if [[ -n "$new_native" || -n "$del_native" ]]; then
        MSG_PARTS="📦 Arch: "
        [[ -n "$new_native" ]] && MSG_PARTS+="+${new_native} "
        [[ -n "$del_native" ]] && MSG_PARTS+="-${del_native}"
    fi

    # --- 2. CAMBIOS AUR ---
    new_aur=$(git diff --cached -U0 "$FILE_AUR" | grep "^+[^+]" | sed 's/^+//' | tr '\n' ' ' | xargs)
    del_aur=$(git diff --cached -U0 "$FILE_AUR" | grep "^-[^-]" | sed 's/^-//' | tr '\n' ' ' | xargs)

    if [[ -n "$new_aur" || -n "$del_aur" ]]; then
        [[ -n "$MSG_PARTS" ]] && MSG_PARTS+=" | "
        MSG_PARTS="${MSG_PARTS}🦄 AUR: "
        [[ -n "$new_aur" ]] && MSG_PARTS+="+${new_aur} "
        [[ -n "$del_aur" ]] && MSG_PARTS+="-${del_aur}"
    fi

    # --- 3. CONFIGS Y ARCHIVOS ELIMINADOS ---
    # Detectamos archivos MODIFICADOS o NUEVOS (excluyendo listas)
    configs=$(git diff --cached --name-only --diff-filter=AM | grep -vE "($FILE_NATIVE|$FILE_AUR)" | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')

    # Detectamos archivos ELIMINADOS físicamente
    deleted_files=$(git diff --cached --name-only --diff-filter=D | grep -vE "($FILE_NATIVE|$FILE_AUR)" | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')

    if [[ -n "$configs" || -n "$deleted_files" ]]; then
        [[ -n "$MSG_PARTS" ]] && MSG_PARTS+=" | "
        MSG_PARTS="${MSG_PARTS}🛠️ Config: "
        [[ -n "$configs" ]] && MSG_PARTS+="modificados: [${configs}] "
        [[ -n "$deleted_files" ]] && MSG_PARTS+="eliminados: [${deleted_files}]"
    fi

    # Fallback de seguridad
    if [[ -z "$MSG_PARTS" ]]; then
        MSG_PARTS="🔄 Sync manual: $(date '+%Y-%m-%d %H:%M')"
    fi

    # --- COMMIT & PUSH ---
    if git commit -m "$MSG_PARTS" >> "$LOG_FILE" 2>&1; then
        if git push >> "$LOG_FILE" 2>&1; then
            notify "✅ Guardado: $MSG_PARTS"
        else
            notify "⚠️ Error al subir (Push fallido)"
        fi
    else
        notify "⚠️ Error en Commit"
    fi
fi
