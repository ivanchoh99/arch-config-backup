#!/bin/bash

export DISPLAY=:0
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus

# PATH fijo y mínimo: evita que directorios escribibles por el usuario
# (p. ej. ~/.local/bin) suplanten binarios del sistema al correr vía systemd.
export PATH="/usr/local/sbin:/usr/local/bin:/usr/bin:/bin"
GIT=/usr/bin/git
YAY=/usr/bin/yay
NOTIFY_SEND=/usr/bin/notify-send

# --- CONFIGURACIÓN ---
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_DIR="$REPO_DIR/pkglist"
LOG_FILE="$HOME/.cache/dotfiles_autoguardado.log"

# Asegurar que el directorio exista
mkdir -p "$PKG_DIR"

# Archivo unificado
FILE_ALL="$PKG_DIR/full-pkglist.txt"

notify() {
    if [[ -x "$NOTIFY_SEND" ]]; then
        "$NOTIFY_SEND" "Dotfiles Sync" "$1" --icon=package-x-generic
    fi
}

# --- GUARD DE SECRETOS ---
# Escanea el contenido que se va a commitear buscando credenciales evidentes.
# Si encuentra algo, NO commitea ni sube: avisa y deja todo en staging.
# (Reduce el riesgo de que un token escrito por una app acabe en GitHub.)
scan_secrets() {
    local hits
    hits="$("$GIT" diff --cached -U0 | grep '^+' | grep -v '^+++' | grep -aEni \
        'ghp_[A-Za-z0-9]{20,}|gho_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|ghs_[A-Za-z0-9]{20,}|sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{10,}|-----BEGIN [A-Z ]*PRIVATE KEY-----|(password|passwd|secret|api[_-]?key|token|access[_-]?key)[[:space:]]*[=:][[:space:]]*[^[:space:]]{8,}' \
        2>/dev/null | head -n 20)"
    [[ -n "$hits" ]]
}

# --- 1. ACTUALIZACIÓN UNIFICADA ---
# yay -Qqe obtiene todos los paquetes instalados explícitamente (Repo + AUR)
"$YAY" -Qqe > "$FILE_ALL"

cd "$REPO_DIR" || exit 1

# Agregamos cambios al índice de Git
"$GIT" add -A

# Guard de secretos: solo se evalúa lo que NO es la lista de paquetes.
if "$GIT" diff --cached --name-only | grep -qvxF "pkglist/full-pkglist.txt"; then
    if scan_secrets; then
        matches="$("$GIT" diff --cached --name-only | grep -vxF "pkglist/full-pkglist.txt" | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')"
        "$GIT" reset -q
        notify "🚫 Posible secreto detectado. Auto-save cancelado. Revisa: [${matches}]"
        exit 1
    fi
fi

# Solo si hay cambios detectados
if [[ -n $("$GIT" status --porcelain) ]]; then

    MSG_PARTS=""

    # --- 2. DETECTAR CAMBIOS EN LA LISTA ÚNICA ---
    # Extraemos líneas nuevas (+) y eliminadas (-)
    new_pkgs=$("$GIT" diff --cached -U0 "$FILE_ALL" | grep "^+[^+]" | sed 's/^+//' | tr '\n' ' ' | xargs)
    del_pkgs=$("$GIT" diff --cached -U0 "$FILE_ALL" | grep "^-[^-]" | sed 's/^-//' | tr '\n' ' ' | xargs)

    if [[ -n "$new_pkgs" || -n "$del_pkgs" ]]; then
        MSG_PARTS="📦 Paquetes: "
        [[ -n "$new_pkgs" ]] && MSG_PARTS+="+${new_pkgs} "
        [[ -n "$del_pkgs" ]] && MSG_PARTS+="-${del_pkgs}"
    fi

    # --- 3. DETECTAR OTROS CAMBIOS (Configuraciones) ---
    configs=$("$GIT" diff --cached --name-only --diff-filter=AM | grep -v "full-pkglist.txt" | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')
    deleted_files=$("$GIT" diff --cached --name-only --diff-filter=D | grep -v "full-pkglist.txt" | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')

    if [[ -n "$configs" || -n "$deleted_files" ]]; then
        [[ -n "$MSG_PARTS" ]] && MSG_PARTS+=" | "
        MSG_PARTS="${MSG_PARTS}🛠 Config: "
        [[ -n "$configs" ]] && MSG_PARTS+="modificados: [${configs}] "
        [[ -n "$deleted_files" ]] && MSG_PARTS+="eliminados: [${deleted_files}]"
    fi

    # --- 4. COMMIT & PUSH ---
    if [[ -z "$MSG_PARTS" ]]; then MSG_PARTS="🔄 Sync: $(date '+%Y-%m-%d %H:%M')"; fi

    if "$GIT" commit -m "$MSG_PARTS" >> "$LOG_FILE" 2>&1; then
        if "$GIT" push >> "$LOG_FILE" 2>&1; then
            notify "✅ Guardado: $MSG_PARTS"
        else
            notify "⚠ Error en Push (revisa conexión o credenciales)"
        fi
    else
        notify "⚠ Error en Commit"
    fi
fi