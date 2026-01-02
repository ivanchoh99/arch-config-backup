#!/bin/bash
# Ir a la carpeta de dotfiles (usa ruta completa)
cd /home/dcloud99/dotfiles || exit

# Solo actuar si hay cambios
if [[ $(git status --porcelain) ]]; then
    # 1. Detectar si el cambio fue por instalar paquetes
    nuevos=$(git diff -U0 pkglist/pkglist.txt | grep "^+[^+]" | sed 's/^+//' | tr '\n' ' ')

    if [[ -n "$nuevos" ]]; then
        mensaje="Instalado: $nuevos"
    else
        mensaje="Update: $(date '+%Y-%m-%d %H:%M')"
    fi

    # 2. Ejecutar la subida
    git add .
    git commit -m "$mensaje"
    git push

    # 3. Notificación visual (opcional)
    notify-send "Dotfiles" "$mensaje"
fi
