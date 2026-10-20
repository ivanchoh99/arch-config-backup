#!/bin/bash

# --- COLORES PARA MENSAJES ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # Sin color

echo -e "${BLUE}=== Automatización de Instalación de YAY ===${NC}"

# --- 1. VERIFICACIÓN PREVIA ---
if command -v yay &> /dev/null; then
    echo -e "${GREEN}✅ 'yay' ya está instalado en este sistema. Omitiendo la instalación.${NC}"
    exit 0
fi

# --- 2. INSTALAR DEPENDENCIAS ---
# base-devel y git son obligatorios para clonar y compilar paquetes de AUR
echo -e "${BLUE}📦 Instalando dependencias necesarias (base-devel y git)...${NC}"
sudo pacman -S --needed --noconfirm base-devel git
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Error al instalar las dependencias. Verifica tu conexión a internet o permisos sudo.${NC}"
    exit 1
fi

# --- 3. CREAR ENTORNO TEMPORAL ---
# Usamos mktemp para crear una carpeta temporal segura en /tmp que se borrará al reiniciar
TEMP_DIR=$(mktemp -d)
echo -e "${BLUE}📂 Usando directorio temporal: $TEMP_DIR${NC}"
cd "$TEMP_DIR" || exit 1

# --- 4. CLONAR AUR ---
echo -e "${BLUE}⬇️ Clonando el repositorio yay-bin desde AUR...${NC}"
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin || exit 1

# --- 5. CONSTRUCCIÓN E INSTALACIÓN ---
# makepkg no se puede ejecutar como root (sudo).
# -s: Instala dependencias si faltan.
# -i: Instala el paquete resultante con pacman.
# --noconfirm: Evita que pregunte (Y/n) durante el proceso.
echo -e "${BLUE}🔨 Compilando e instalando...${NC}"
makepkg -si --noconfirm
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ ¡yay se instaló correctamente!${NC}"
else
    echo -e "${RED}❌ Ocurrió un error durante la compilación/instalación con makepkg.${NC}"
fi

# --- 6. LIMPIEZA ---
echo -e "${BLUE}🧹 Limpiando archivos temporales...${NC}"
cd ~ || exit 1
rm -rf "$TEMP_DIR"

echo -e "${GREEN}=== Proceso finalizado ===${NC}"