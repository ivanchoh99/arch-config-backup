#!/bin/bash

# --- Orquestador de configuración Arch ---
# Ejecuta en orden: yay -> paquetes -> dotfiles -> fuente -> aspecto visual -> auto-save
# Cada paso es opcional (s/n). El estado se acumula para un resumen final honesto.

# --- CONFIGURACIÓN DE RUTAS (relativas a este script) ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_YAY="$SCRIPT_DIR/yay-install.sh"
SCRIPT_RESTORE="$SCRIPT_DIR/restore-package.sh"
SCRIPT_DEPLOY="$SCRIPT_DIR/deploy.sh"
SCRIPT_AUTOSAVE="$SCRIPT_DIR/auto-save.sh"

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

# --- Registro de resultados para el resumen final ---
RESULTS=()          # pares "nombre|estado" (ok | omitido | fallido)
FAILED=0            # contador de fallos
SKIPPED=0           # contador de omisiones
OK=0                # contador de éxitos

record() {  # record "nombre" "estado"
    RESULTS+=("$1|$2")
    case "$2" in
        ok)       OK=$((OK+1)) ;;
        omitido)  SKIPPED=$((SKIPPED+1)) ;;
        fallido)  FAILED=$((FAILED+1)) ;;
    esac
}

# Función para ejecutar cada script con validación.
# Devuelve 0 si el paso terminó bien (o se omitió), 1 si falló.
run_step() {
    local script=$1
    local name=$2

    echo -e "\n${YELLOW}▶ Próximo paso: $name${NC}"

    if [[ ! -f "$script" ]]; then
        echo -e "${RED}❌ Error: No se encuentra '$script'.${NC}"
        record "$name" "fallido"
        return 1
    fi

    chmod +x "$script"

    read -p "¿Deseas ejecutarlo ahora? (s/n): " confirm
    if [[ "$confirm" =~ ^[sS]$ ]]; then
        if bash "$script"; then
            record "$name" "ok"
            return 0
        else
            echo -e "${RED}⚠ El paso '$name' terminó con errores.${NC}"
            record "$name" "fallido"
            return 1
        fi
    else
        echo -e "${BLUE}⏭ Omitiendo $name...${NC}"
        record "$name" "omitido"
        return 0
    fi
}

# --- FLUJO DE INSTALACIÓN ---

# 1. Instalar Yay (si no existe)
run_step "$SCRIPT_YAY" "Instalación de Yay (AUR Helper)"

# 2. Restaurar Paquetes (solo si el paso 1 no falló)
if [[ $? -eq 0 ]]; then
    run_step "$SCRIPT_RESTORE" "Restauración de paquetes desde pkglist/"
    step_pkg=$?
else
    echo -e "${RED}⚠ Hubo un problema con Yay. Revisa antes de continuar.${NC}"
    step_pkg=1
fi

# 3. Desplegar dotfiles (symlinks)
if [[ $step_pkg -eq 0 ]]; then
    run_step "$SCRIPT_DEPLOY" "Despliegue de dotfiles (symlinks)"
    step_deploy=$?
else
    echo -e "${RED}⚠ Hubo un problema con los paquetes. Revisa antes de continuar.${NC}"
    step_deploy=1
fi

# 4. Fuente (solo si el despliegue no falló)
echo -e "\n${BLUE}==========================================${NC}"
if [[ $step_deploy -eq 0 ]]; then
    read -p "¿Deseas instalar la fuente JetBrainsMono Nerd Font? (s/n): " install_fonts
    if [[ "$install_fonts" =~ ^[sS]$ ]]; then
        if bash "$SCRIPT_DEPLOY" --install-fonts; then
            record "Fuente JetBrainsMono Nerd Font" "ok"
        else
            record "Fuente JetBrainsMono Nerd Font" "fallido"
        fi
    else
        echo -e "${BLUE}⏭ Omitiendo instalación de fuente...${NC}"
        record "Fuente JetBrainsMono Nerd Font" "omitido"
    fi
else
    echo -e "${RED}⚠ No se puede instalar la fuente: falló el despliegue de dotfiles.${NC}"
    record "Fuente JetBrainsMono Nerd Font" "fallido"
fi

# 5. Aspecto visual (tema, iconos, cursor, decoración, wallpaper)
echo -e "\n${BLUE}==========================================${NC}"
read -p "¿Deseas aplicar el aspecto visual completo (Look and Feel)? (s/n): " apply_look
if [[ "$apply_look" =~ ^[sS]$ ]]; then
    if bash "$SCRIPT_DEPLOY" --apply-look; then
        record "Aspecto visual (Look and Feel)" "ok"
    else
        record "Aspecto visual (Look and Feel)" "fallido"
    fi
else
    echo -e "${BLUE}⏭ Omitiendo aspecto visual...${NC}"
    record "Aspecto visual (Look and Feel)" "omitido"
fi

# 6. Guardado Inicial / Sincronización
echo -e "\n${BLUE}==========================================${NC}"
read -p "¿Deseas ejecutar una sincronización (auto-save) inicial? (s/n): " sync_now
if [[ "$sync_now" =~ ^[sS]$ ]]; then
    if bash "$SCRIPT_AUTOSAVE"; then
        record "Sincronización (auto-save)" "ok"
    else
        record "Sincronización (auto-save)" "fallido"
    fi
else
    echo -e "${BLUE}⏭ Omitiendo sincronización...${NC}"
    record "Sincronización (auto-save)" "omitido"
fi

# 7. Habilitar sincronización automática con systemd (usuario)
echo -e "\n${BLUE}==========================================${NC}"
read -p "¿Deseas habilitar la sincronización automática con systemd (dotfiles.path)? (s/n): " enable_systemd
if [[ "$enable_systemd" =~ ^[sS]$ ]]; then
    echo -e "${BLUE}⚙ Configurando unidades systemd para el usuario...${NC}"
    mkdir -p "$HOME/.config/systemd/user"

    if [[ -f "$SCRIPT_DIR/systemd/dotfiles.service" && -f "$SCRIPT_DIR/systemd/dotfiles.path" ]]; then
        ln -sf "$SCRIPT_DIR/systemd/dotfiles.service" "$HOME/.config/systemd/user/"
        ln -sf "$SCRIPT_DIR/systemd/dotfiles.path" "$HOME/.config/systemd/user/"
        systemctl --user daemon-reload

        if systemctl --user enable --now dotfiles.path >/dev/null 2>&1; then
            echo -e "${GREEN}✓ dotfiles.path habilitado y en ejecución${NC}"
            record "Sincronización automática (systemd)" "ok"
        else
            echo -e "${RED}✗ No se pudo habilitar dotfiles.path${NC}"
            record "Sincronización automática (systemd)" "fallido"
        fi
    else
        echo -e "${RED}✗ No se encuentran las unidades en $SCRIPT_DIR/systemd/${NC}"
        record "Sincronización automática (systemd)" "fallido"
    fi
else
    echo -e "${BLUE}⏭ Omitiendo habilitación de systemd...${NC}"
    record "Sincronización automática (systemd)" "omitido"
fi

# 8. Configuración de Git + SSH (identidad, clave y remote SSH)
echo -e "\n${BLUE}==========================================${NC}"
read -p "¿Deseas configurar Git y la clave SSH (recomendado para el auto-save)? (s/n): " setup_git
if [[ "$setup_git" =~ ^[sS]$ ]]; then
    if bash "$SCRIPT_DEPLOY" --setup-git; then
        record "Configuración de Git y SSH" "ok"
    else
        record "Configuración de Git y SSH" "fallido"
    fi
else
    echo -e "${BLUE}⏭ Omitiendo configuración de Git/SSH...${NC}"
    record "Configuración de Git y SSH" "omitido"
fi

# --- RESUMEN FINAL (honesto) ---
echo -e "\n${BLUE}==========================================${NC}"
echo -e "${BLUE}   RESUMEN FINAL                          ${NC}"
echo -e "${BLUE}==========================================${NC}"
for r in "${RESULTS[@]}"; do
    name="${r%%|*}"
    state="${r##*|}"
    case "$state" in
        ok)       printf "${GREEN}  ✓ %-45s OK${NC}\n" "$name" ;;
        omitido)  printf "${YELLOW}  ⏭ %-45s omitido${NC}\n" "$name" ;;
        fallido)  printf "${RED}  ✗ %-45s FALLÓ${NC}\n" "$name" ;;
    esac
done

echo ""
if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}✅ Configuración terminada: $OK paso(s) OK, $SKIPPED omitido(s).${NC}"
else
    echo -e "${RED}⚠ Configuración terminada con problemas: $OK OK, $SKIPPED omitido(s), $FAILED fallido(s).${NC}"
    echo -e "${RED}  Revisa los pasos marcados con ✗ arriba.${NC}"
fi
