#!/bin/bash

# --- Despliegue de dotfiles: crea symlinks repo -> home ---
# Uso: bash deploy.sh [--install-fonts] [--apply-look]
#   (sin flags)      -> solo enlaza los dotfiles
#   --install-fonts  -> SOLO instala la fuente JetBrainsMono Nerd Font
#   --apply-look     -> SOLO aplica el aspecto visual (tema, iconos, cursor, wallpaper)
# Backups de archivos existentes se guardan en ~/.dotfiles-backup-<fecha>/

set -uo pipefail   # sin -e: un archivo faltante no debe abortar todo el despliegue

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Parseo de argumentos ---
WANT_LINKS=1
WANT_FONTS=0
WANT_LOOK=0
for arg in "$@"; do
    case "$arg" in
        --install-fonts) WANT_FONTS=1; WANT_LINKS=0 ;;
        --apply-look)    WANT_LOOK=1; WANT_LINKS=0 ;;
        *) echo -e "${YELLOW}⚠ Opción desconocida ignorada: $arg${NC}" ;;
    esac
done

# ============================================================
# 1. ENLACES repo -> home
# ============================================================
if [[ $WANT_LINKS -eq 1 ]]; then
    echo -e "${BLUE}=== Despliegue de Dotfiles ===${NC}"
    echo -e "Repo: ${YELLOW}$REPO_DIR${NC}"

    # Cada par es: ruta_del_repo|ruta_del_home
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
      "kde/.local/share/wallpapers/Dotfiles|$HOME/.local/share/wallpapers/Dotfiles"
      "kde/.local/share/aurorae/themes/Ant-Dark|$HOME/.local/share/aurorae/themes/Ant-Dark"
      "kde/.local/share/aurorae/themes/Layan|$HOME/.local/share/aurorae/themes/Layan"
      "kde/.local/share/aurorae/themes/Otto-Light|$HOME/.local/share/aurorae/themes/Otto-Light"
      "konsole/.local/share/konsole/Breeze.colorscheme|$HOME/.local/share/konsole/Breeze.colorscheme"
      "konsole/.local/share/konsole/dcloud99.profile|$HOME/.local/share/konsole/dcloud99.profile"
      "bash/.bashrc|$HOME/.bashrc"
    )

    # Contadores para el resumen
    n_ok=0; n_already=0; n_backup=0; n_missing=0; missing_list=()

    link_file() {
        local src="$REPO_DIR/$1"
        local dst="$2"

        if [[ ! -e "$src" ]]; then
            echo -e "${RED}✗ No existe en repo: $src${NC}"
            n_missing=$((n_missing+1)); missing_list+=("$1")
            return 1
        fi

        mkdir -p "$(dirname "$dst")"

        if [[ -L "$dst" ]]; then
            if [[ "$(readlink "$dst")" == *"dotfiles/$1"* ]]; then
                echo -e "${YELLOW}↺ Ya enlazado: $dst${NC}"
                n_already=$((n_already+1))
                return 0
            fi
            rm "$dst"
        elif [[ -e "$dst" ]]; then
            local backup_target="$BACKUP_DIR/$1"
            mkdir -p "$BACKUP_DIR" "$(dirname "$backup_target")"
            mv "$dst" "$backup_target"
            echo -e "${YELLOW}⇢ Backup de $dst → $backup_target${NC}"
            n_backup=$((n_backup+1))
        fi

        local rel
        rel="$(realpath --relative-to="$(dirname "$dst")" "$src")"
        ln -s "$rel" "$dst"
        echo -e "${GREEN}✓ Enlazado: $dst → $rel${NC}"
        n_ok=$((n_ok+1))
    }

    for pair in "${LINKS[@]}"; do
        src="${pair%%|*}"
        dst="${pair#*|}"
        link_file "$src" "$dst"
    done

    echo ""
    echo -e "${BLUE}--- Resumen de enlaces ---${NC}"
    echo -e "${GREEN}  Enlazados nuevos: $n_ok${NC}  |  Ya existían: $n_already  |  Respaldados: $n_backup  |  Faltantes: $n_missing"
    if [[ $n_missing -gt 0 ]]; then
        for m in "${missing_list[@]}"; do echo -e "    ${RED}• $m${NC}"; done
    fi
    if [[ $n_missing -gt 0 ]]; then
        echo -e "${YELLOW}⚠ Despliegue incompleto: faltan $n_missing archivo(s) en el repo.${NC}"
        exit 2
    fi
    echo -e "${GREEN}✅ Despliegue completado. Reinicia la sesión de KDE para aplicar los cambios.${NC}"
fi

# ============================================================
# 2. FUENTE JetBrainsMono Nerd Font (aislada con --install-fonts)
# ============================================================
if [[ $WANT_FONTS -eq 1 ]]; then
    echo -e "${BLUE}=== Instalación de fuente JetBrainsMono Nerd Font ===${NC}"
    FONT_7Z="$REPO_DIR/oh-my-posh/font/JetBrainsMono.7z"
    FONT_DIR="$HOME/.local/share/fonts"

    if [[ ! -f "$FONT_7Z" ]]; then
        echo -e "${RED}✗ No se encuentra el archivo de la fuente: $FONT_7Z${NC}"
        exit 1
    fi

    if ! command -v 7z >/dev/null 2>&1; then
        echo -e "${RED}✗ '7z' no está instalado.${NC}"
        echo -e "${YELLOW}  Instálalo con: yay -S p7zip${NC}"
        exit 1
    fi

    mkdir -p "$FONT_DIR"
    echo -e "${BLUE}⇢ Extrayendo JetBrainsMono Nerd Font...${NC}"
    if 7z x -y "$FONT_7Z" -o"$FONT_DIR" >/dev/null; then
        fc-cache -f "$FONT_DIR" >/dev/null 2>&1
        echo -e "${GREEN}✓ Fuente instalada en $FONT_DIR.${NC}"
    else
        echo -e "${RED}✗ Error al extraer la fuente.${NC}"
        exit 1
    fi
fi

# ============================================================
# 3. APLICAR ASPECTO VISUAL (tema, iconos, cursor, decoración, wallpaper)
# ============================================================
if [[ $WANT_LOOK -eq 1 ]]; then
    echo -e "${BLUE}=== Aplicando aspecto visual (Look and Feel) ===${NC}"

    # Detecta el paquete activo desde kdeglobals (o usa el known por defecto)
    LOOK_PKG="$(grep -m1 '^LookAndFeelPackage=' "$HOME/.config/kdeglobals" 2>/dev/null | cut -d= -f2-)"
    [[ -z "$LOOK_PKG" ]] && LOOK_PKG="Darck Custome theme 1"

    if ! command -v plasma-apply-lookandfeel >/dev/null 2>&1; then
        echo -e "${RED}✗ 'plasma-apply-lookandfeel' no está disponible (requiere plasma-workspace).${NC}"
        exit 1
    fi

    # Sin sesión KDE activa no es un error: el theme ya está enlazado y
    # kdeglobals apunta a él (LookAndFeelPackage), así que Plasma lo aplicará
    # automáticamente al iniciar sesión.
    if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
        echo -e "${YELLOW}⚠ No hay sesión KDE activa.${NC}"
        echo -e "${YELLOW}  El tema se aplicará solo al iniciar Plasma (theme enlazado + LookAndFeelPackage).${NC}"
        exit 0
    fi

    echo -e "${BLUE}⇢ Aplicando paquete global: ${YELLOW}$LOOK_PKG${NC}"

    # plasma-apply-lookandfeel escribe los defaults del theme en
    # ~/.config/kdedefaults/ (capa de prioridad máxima de KDE): iconos, cursor,
    # widget style, decoración, plasma theme, splash y layout de escritorio.
    if plasma-apply-lookandfeel -a "$LOOK_PKG" >/dev/null 2>&1; then
        echo -e "${GREEN}  ✓ Look and Feel aplicado (defaults escritos en ~/.config/kdedefaults/).${NC}"
    else
        echo -e "${YELLOW}  ⚠ plasma-apply-lookandfeel falló; el tema se aplicará al iniciar Plasma.${NC}"
    fi

    # Wallpaper: paquete 'Dotfiles' resuelto por nombre (sin ruta de usuario)
    WALL_PKG="$HOME/.local/share/wallpapers/Dotfiles"
    if command -v plasma-apply-wallpaperimage >/dev/null 2>&1 && [[ -e "$WALL_PKG" ]]; then
        if plasma-apply-wallpaperimage "$WALL_PKG" >/dev/null 2>&1; then
            echo -e "${GREEN}  ✓ Wallpaper 'Dotfiles' aplicado.${NC}"
        else
            echo -e "${YELLOW}  ⚠ No se pudo fijar el wallpaper vía CLI (se usa el layout del tema).${NC}"
        fi
    fi

    # Refresca la caché de iconos/esquemas
    kbuildsycoca6 >/dev/null 2>&1 || true

    # --- Verificación leyendo kdedefaults/ (la fuente real de la apariencia) ---
    D="$HOME/.config/kdedefaults"
    _kd() { grep -m1 "^$2=" "$D/$1" 2>/dev/null | cut -d= -f2-; }
    echo -e "${BLUE}  --- Verificación de la apariencia (kdedefaults/) ---${NC}"
    printf "    Iconos:      %s\n" "$(_kd kdeglobals Theme)"
    printf "    Cursor:      %s\n" "$(_kd kcminputrc cursorTheme)"
    printf "    Estilo:      %s\n" "$(_kd kdeglobals widgetStyle)"
    printf "    Decoración:  %s\n" "$(_kd kwinrc library)"
    printf "    Plasma:      %s\n" "$(_kd plasmarc name)"
    printf "    Splash:      %s\n" "$(_kd ksplashrc Theme)"

    echo -e "${GREEN}✓ Aspecto visual replicado: tema, iconos, cursor, decoración, plasma theme y wallpaper.${NC}"
    echo -e "${YELLOW}  Reinicia la sesión de KDE si algún cambio no se refleja en caliente.${NC}"
fi
