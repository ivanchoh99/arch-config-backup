# Dotfiles Arch Linux — Configuración y Backup

Backup de configuración de escritorio (KDE Plasma) y aplicaciones para Arch Linux.

## Estructura del repo

```
dotfiles/
├── bash/                     # ~/.bashrc (aliases, PATH: Java, fnm, conda, podman...)
├── kde/
│   ├── .config/              # → ~/.config/
│   │   ├── kdeglobals        #   Colores, tema activo (Light Custome v1.1)
│   │   ├── kwinrc            #   Tiling, atajos del gestor de ventanas
│   │   ├── kwinoutputconfig.json  #   Layout de monitores (hardware específico)
│   │   ├── plasmarc          #   Wallpaper
│   │   ├── plasma-org.kde.plasma.desktop-appletsrc  # Widgets del escritorio
│   │   ├── plasmashellrc     #   Paneles
│   │   └── kglobalshortcutsrc #   Atajos globales
│   ├── .local/share/         # → ~/.local/share/
│   │   ├── color-schemes/    #   LayanLight.colors
│   │   ├── plasma/look-and-feel/  #  Temas "Light Custome v1.1", "Darck Custome theme 1", Otto-Light
│   │   ├── plasma/desktoptheme/   #  Otto-Light
│   │   └── aurorae/themes/   #   Decoraciones de ventana (Ant-Dark, Layan, Otto-Light)
│   └── wallpapers/           # Imagen de fondo usada por plasmarc
├── konsole/                  # Perfil y esquema de color de Konsole
├── oh-my-posh/
│   ├── theme/mytheme.omp.json    # Prompt (el que usa .bashrc)
│   └── font/JetBrainsMono.7z     # Fuente JetBrainsMono Nerd Font (solo familia Mono)
├── pkglist/full-pkglist.txt  # Lista de paquetes explícitos (yay -Qqe)
├── systemd/                  # Unidades: auto-commit de cambios cada vez que algo se modifica
├── auto-save.sh              # Detecta cambios, hace commit y push automático
├── deploy.sh                 # Enlaza (symlinks) los archivos del repo a tu home
├── yay-install.sh            # Instala yay (AUR helper)
├── restore-package.sh        # Reinstala todos los paquetes de pkglist/
└── setup-system.sh           # Orquestador: yay → restore-package → sync
```

## Flujo de restauración (tras reinstalar Arch)

```bash
# 1. Clonar el repo
git clone git@github.com:ivanchoh99/arch-config-backup.git ~/dotfiles

# 2. Instalar yay (si no existe)
bash ~/dotfiles/yay-install.sh

# 3. Reinstalar todos los paquetes (repo + AUR)
bash ~/dotfiles/restore-package.sh

# 4. Desplegar dotfiles (symlinks + fuente)
bash ~/dotfiles/deploy.sh --install-fonts

# 5. Reactivar el auto-save
systemctl --user enable --now dotfiles.path

# 6. Reiniciar sesión de KDE
```

## Notas

- **Rutas hardcodeadas**: la config usa `$HOME=/home/dcloud99` y el repo vive en `~/dotfiles`. Si cambias de usuario o ruta, ajusta `deploy.sh` y las rutas de `kde/.config/*` (wallpaper).
- **Monitores**: `kwinoutputconfig.json` contiene EDIDs/UUIDs de pantallas concretas; el layout solo se recupera con los mismos monitores.
- **Seguridad**: no commitear tokens o claves en los temas (ej. segmentos de oh-my-posh tipo "strava"). Usa variables de entorno.
- **Auto-save**: `systemd/dotfiles.path` vigila `kde/.config/`, `kde/.local/`, `kde/wallpapers/`, etc. y `auto-save.sh` genera el commit con los paquetes nuevos/eliminados y configs modificadas.
