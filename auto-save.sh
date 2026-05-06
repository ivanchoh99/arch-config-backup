#!/bin/bash

export DISPLAY=:0
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus

# --- CONFIGURACIÓN ---
REPO_DIR="$HOME/dotfiles"
PKG_DIR="$REPO_DIR/pkglist"
LOG_FILE="$HOME/.cache/dotfiles_autoguardado.log"

# Asegurar que el directorio exista
mkdir -p "$PKG_DIR"

# Archivo unificado
FILE_ALL="$PKG_DIR/full-pkglist.txt"

notify() {
    if command -v notify-send >/dev/null; then
        notify-send "Dotfiles Sync" "$1" --icon=package-x-generic
    fi
}

# --- 1. ACTUALIZACIÓN UNIFICADA ---
# yay -Qqe obtiene todos los paquetes instalados explícitamente (Repo + AUR)
yay -Qqe > "$FILE_ALL"

cd "$REPO_DIR" || exit 1

# Agregamos cambios al índice de Git
git add -A

# Solo si hay cambios detectados
if [[ -n $(git status --porcelain) ]]; then

    MSG_PARTS=""

    # --- 2. DETECTAR CAMBIOS EN LA LISTA ÚNICA ---
    # Extraemos líneas nuevas (+) y eliminadas (-)
    new_pkgs=$(git diff --cached -U0 "$FILE_ALL" | grep "^+[^+]" | sed 's/^+//' | tr '\n' ' ' | xargs)
    del_pkgs=$(git diff --cached -U0 "$FILE_ALL" | grep "^-[^-]" | sed 's/^-//' | tr '\n' ' ' | xargs)

    if [[ -n "$new_pkgs" || -n "$del_pkgs" ]]; then
        MSG_PARTS="📦 Paquetes: "
        [[ -n "$new_pkgs" ]] && MSG_PARTS+="+${new_pkgs} "
        [[ -n "$del_pkgs" ]] && MSG_PARTS+="-${del_pkgs}"
    fi

    # --- 3. DETECTAR OTROS CAMBIOS (Configuraciones) ---
    configs=$(git diff --cached --name-only --diff-filter=AM | grep -v "full-pkglist.txt" | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')
    deleted_files=$(git diff --cached --name-only --diff-filter=D | grep -v "full-pkglist.txt" | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')

    if [[ -n "$configs" || -n "$deleted_files" ]]; then
        [[ -n "$MSG_PARTS" ]] && MSG_PARTS+=" | "
        MSG_PARTS="${MSG_PARTS}🛠 Config: "
        [[ -n "$configs" ]] && MSG_PARTS+="modificados: [${configs}] "
        [[ -n "$deleted_files" ]] && MSG_PARTS+="eliminados: [${deleted_files}]"
    fi

    # --- 4. COMMIT & PUSH ---
    if [[ -z "$MSG_PARTS" ]]; then MSG_PARTS="🔄 Sync: $(date '+%Y-%m-%d %H:%M')"; fi

    if git commit -m "$MSG_PARTS" >> "$LOG_FILE" 2>&1; then
        if git push >> "$LOG_FILE" 2>&1; then
            notify "✅ Guardado: $MSG_PARTS"
        else
            notify "⚠ Error en Push (revisa conexión o credenciales)"
        fi
    else
        notify "⚠ Error en Commit"
    fi
fi