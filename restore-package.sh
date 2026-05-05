#!/bin/bash

# --- CONFIGURACIÓN ---
REPO_DIR="$HOME/dotfiles"
FILE_ALL="$REPO_DIR/pkglist/full-pkglist.txt"

# Colores para la terminal
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== Restauración de Paquetes (Arch + AUR) ===${NC}"

# --- 1. VALIDACIONES INICIALES ---

# Verificar si yay existe
if ! command -v yay &> /dev/null; then
    echo -e "${RED}❌ 'yay' no está instalado. Por favor, corre primero el script de instalación de yay.${NC}"
    exit 1
fi

# Verificar si el archivo de lista existe
if [[ ! -f "$FILE_ALL" ]]; then
    echo -e "${RED}❌ No se encontró la lista de paquetes en: $FILE_ALL${NC}"
    exit 1
fi

# --- 2. SINCRONIZACIÓN DE REPOSITORIOS ---
echo -e "${BLUE}🔄 Actualizando bases de datos de paquetes...${NC}"
yay -Sy

# --- 3. INSTALACIÓN MASIVA ---
echo -e "${BLUE}📦 Instalando paquetes desde la lista...${NC}"

# --needed: No reinstala lo que ya tienes.
# --noconfirm: Instalación desatendida.
# - < "$FILE_ALL": Lee los nombres directamente desde tu archivo.
if yay -S --needed --noconfirm - < "$FILE_ALL"; then
    echo -e "${GREEN}✅ ¡Todos los paquetes han sido instalados o actualizados!${NC}"
else
    echo -e "${RED}❌ Hubo un error durante la instalación masiva.${NC}"
    exit 1
fi

echo -e "${GREEN}=== Proceso completado con éxito ===${NC}"