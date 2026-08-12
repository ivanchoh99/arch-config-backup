#!/bin/bash

# --- CONFIGURACIÓN DE RUTAS (Basado en tu estructura actual) ---
SCRIPT_YAY="./yay-install.sh"
SCRIPT_RESTORE="./restore-package.sh"
SCRIPT_DEPLOY="./deploy.sh"
SCRIPT_AUTOSAVE="./auto-save.sh"

# Colores para la terminal
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}   ORQUESTADOR DE CONFIGURACIÓN ARCH      ${NC}"
echo -e "${BLUE}==========================================${NC}"

# Función para ejecutar cada script con validación
run_step() {
    local script=$1
    local name=$2

    echo -e "\n${YELLOW}▶ Próximo paso: $name${NC}"
    
    if [[ ! -f "$script" ]]; then
        echo -e "${RED}❌ Error: No se encuentra '$script' en la carpeta actual.${NC}"
        return 1
    fi

    chmod +x "$script"
    
    read -p "¿Deseas ejecutarlo ahora? (s/n): " confirm
    if [[ "$confirm" =~ ^[sS]$ ]]; then
        bash "$script"
        return $?
    else
        echo -e "${BLUE}⏭ Omitiendo $name...${NC}"
        return 0
    fi
}

# --- FLUJO DE INSTALACIÓN ---

# 1. Instalar Yay (Si no existe)
run_step "$SCRIPT_YAY" "Instalación de Yay (AUR Helper)"

# 2. Restaurar Paquetes
if [[ $? -eq 0 ]]; then
    run_step "$SCRIPT_RESTORE" "Restauración de paquetes desde pkglist/"
else
    echo -e "${RED}⚠ Hubo un problema con la base del sistema. Revisa antes de continuar.${NC}"
fi

# 3. Desplegar dotfiles (symlinks repo -> home)
if [[ $? -eq 0 ]]; then
    run_step "$SCRIPT_DEPLOY" "Despliegue de dotfiles (symlinks)"

    # 4. Fuente (opcional, si se desplegó)
    echo -e "\n${BLUE}==========================================${NC}"
    read -p "¿Deseas instalar la fuente JetBrainsMono Nerd Font? (s/n): " install_fonts
    if [[ "$install_fonts" =~ ^[sS]$ ]]; then
        bash "$SCRIPT_DEPLOY" --install-fonts
    else
        echo -e "${BLUE}⏭ Omitiendo instalación de fuente...${NC}"
    fi
else
    echo -e "${RED}⚠ Hubo un problema con la base del sistema. Revisa antes de continuar.${NC}"
fi

# 5. Guardado Inicial / Sincronización
echo -e "\n${BLUE}==========================================${NC}"
read -p "¿Deseas ejecutar una sincronización (auto-save) inicial? (s/n): " sync_now
if [[ "$sync_now" =~ ^[sS]$ ]]; then
    bash "$SCRIPT_AUTOSAVE"
fi

echo -e "\n${GREEN}✅ Entorno configurado correctamente.${NC}"