#!/bin/bash

# --- Despliegue de dotfiles: crea symlinks repo -> home ---
# Uso: bash deploy.sh [--install-fonts]
# Backups de archivos existentes se guardan en ~/.dotfiles-backup-<fecha>/

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Despliegue de Dotfiles ===${NC}"
echo -e "Repo: ${YELLOW}$REPO_DIR${NC}"

# --- 1. Enlaces repo -> home (cada par es: ruta_del_repo|ruta_del_home) ---
LINKS=(
  "kde/.config/kdeglobals|$HOME/.config/kdeglobals"
  "kde/.config/kwinrc|$HOME/.config/kwinrc"
  "kde/.config/kwinoutputconfig.json|$HOME/.config/kwinoutputconfig.json"
  "kde/.config/plasmarc|$HOME/.config/plasmarc"
  "kde/.config/plasma-org.kde.plasma.desktop-appletsrc|$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
  "kde/.config/plasmashellrc|$HOME/.config/plasmashellrc"
  "kde/.config/kglobalshortcutsrc|$HOME/.config/kglobalshortcutsrc"
  "kde/.local/share/color-schemes/LayanLight.colors|$HOME/.local/share/color-schemes/LayanLight.colors"
  "kde/.local/share/plasma/look-and-feel/Light Custome v1.1|$HOME/.local/share/plasma/look-and-feel/Light Custome v1.1"
  "kde/.local/share/plasma/look-and-feel/Darck Custome theme 1|$HOME/.local/share/plasma/look-and-feel/Darck Custome theme 1"
  "kde/.local/share/plasma/look-and-feel/Otto-Light|$HOME/.local/share/plasma/look-and-feel/Otto-Light"
  "kde/.local/share/plasma/desktoptheme/Otto-Light|$HOME/.local/share/plasma/desktoptheme/Otto-Light"
  "kde/.local/share/aurorae/themes/Ant-Dark|$HOME/.local/share/aurorae/themes/Ant-Dark"
  "kde/.local/share/aurorae/themes/Layan|$HOME/.local/share/aurorae/themes/Layan"
  "kde/.local/share/aurorae/themes/Otto-Light|$HOME/.local/share/aurorae/themes/Otto-Light"
  "konsole/.local/share/konsole/Breeze.colorscheme|$HOME/.local/share/konsole/Breeze.colorscheme"
  "konsole/.local/share/konsole/dcloud99.profile|$HOME/.local/share/konsole/dcloud99.profile"
  "bash/.bashrc|$HOME/.bashrc"
)

link_file() {
    local src="$REPO_DIR/$1"
    local dst="$2"

    [[ -e "$src" ]] || { echo -e "${RED}✗ No existe en repo: $src${NC}"; return 1; }

    mkdir -p "$(dirname "$dst")"

    if [[ -L "$dst" ]]; then
        if [[ "$(readlink "$dst")" == *"dotfiles/$1"* ]]; then
            echo -e "${YELLOW}↺ Ya enlazado: $dst${NC}"
            return 0
        fi
        rm "$dst"
    elif [[ -e "$dst" ]]; then
        local backup_target="$BACKUP_DIR/$1"
        mkdir -p "$BACKUP_DIR" "$(dirname "$backup_target")"
        mv "$dst" "$backup_target"
        echo -e "${YELLOW}⇢ Backup de $dst → $backup_target${NC}"
    fi

    local rel
    rel="$(realpath --relative-to="$(dirname "$dst")" "$src")"
    ln -s "$rel" "$dst"
    echo -e "${GREEN}✓ Enlazado: $dst → $rel${NC}"
}

for pair in "${LINKS[@]}"; do
    src="${pair%%|*}"
    dst="${pair#*|}"
    link_file "$src" "$dst"
done

# --- 2. Fuente JetBrains Mono Nerd Font (opcional) ---
if [[ "${1:-}" == "--install-fonts" ]]; then
    FONT_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"
    if command -v 7z >/dev/null 2>&1; then
        echo -e "${BLUE}⇢ Instalando JetBrainsMono Nerd Font...${NC}"
        7z x -y "$REPO_DIR/oh-my-posh/font/JetBrainsMono.7z" -o"$FONT_DIR" >/dev/null
        fc-cache -f "$FONT_DIR" >/dev/null 2>&1
        echo -e "${GREEN}✓ Fuente instalada.${NC}"
    else
        echo -e "${RED}✗ '7z' no está instalado. Instala p7zip o descomprime el .7z manualmente.${NC}"
    fi
fi

echo -e "${GREEN}✅ Despliegue completado. Reinicia la sesión de KDE para aplicar los cambios.${NC}"
