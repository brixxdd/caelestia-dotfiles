#!/bin/bash
# =============================================
# Brixxdd Dotfiles Installer
# Instalador interactivo para CachyOS / Arch
# =============================================

# ── Colores para terminal ─────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOTFILES_DIR="$HOME/caelestia"
SCRIPTS_DIR="$HOME/.local/bin"

log()  { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
err()  { echo -e "${RED}✗${NC} $1"; }
step() { echo -e "\n${BLUE}──${NC} $1"; }

# ── Verificar dependencias básicas ────────────────────────────────────────────
check_base() {
  if ! command -v paru &>/dev/null; then
    err "paru no encontrado. Instalando..."
    sudo pacman -S --needed base-devel
    git clone https://aur.archlinux.org/paru.git /tmp/paru
    cd /tmp/paru && makepkg -si --noconfirm
    cd ~
  fi
  if ! command -v zenity &>/dev/null; then
    sudo pacman -S --noconfirm zenity
  fi
}

# ── Bienvenida ────────────────────────────────────────────────────────────────
welcome() {
  zenity --info \
    --title="Brixxdd Dotfiles Installer" \
    --text="Bienvenido al instalador de tu setup.\n\nEste script instalará:\n• Paquetes del sistema\n• Apps de desarrollo\n• Apps personales\n• Dependencias de scripts\n• Dotfiles y configuración\n\nElige qué instalar en cada categoría." \
    --width=420 --ok-label="Comenzar"
}

# ── Categoría: Sistema base ───────────────────────────────────────────────────
install_base() {
  step "Sistema base"
  PKGS=$(zenity --list --checklist \
    --title="Sistema base" \
    --text="Selecciona los paquetes base a instalar:" \
    --column="✓" --column="Paquete" --column="Descripción" \
    TRUE  "hyprland"              "Compositor Wayland" \
    TRUE  "hyprlock"              "Pantalla de bloqueo" \
    TRUE  "hyprpolkitagent"       "Agente Polkit para Hyprland" \
    TRUE  "uwsm"                  "Gestor de sesión Wayland" \
    TRUE  "sddm"                  "Display manager" \
    TRUE  "xdg-desktop-portal-hyprland" "Portal XDG para Hyprland" \
    TRUE  "xdg-user-dirs"         "Directorios de usuario" \
    TRUE  "networkmanager"        "Gestor de red" \
    TRUE  "bluez"                 "Bluetooth" \
    TRUE  "bluez-utils"           "Utilidades Bluetooth" \
    TRUE  "pipewire-alsa"         "Audio PipeWire" \
    TRUE  "pipewire-pulse"        "PulseAudio via PipeWire" \
    TRUE  "wireplumber"           "Gestor de sesión PipeWire" \
    TRUE  "power-profiles-daemon" "Perfiles de energía" \
    TRUE  "ufw"                   "Firewall" \
    --separator=" " --width=600 --height=500)

  [ -z "$PKGS" ] && return
  sudo pacman -S --needed --noconfirm $PKGS
  log "Sistema base instalado"
}

# ── Categoría: Fuentes y temas ────────────────────────────────────────────────
install_fonts_themes() {
  step "Fuentes y temas"
  PKGS=$(zenity --list --checklist \
    --title="Fuentes y temas" \
    --column="✓" --column="Paquete" --column="Descripción" \
    TRUE  "ttf-meslo-nerd"        "Nerd Font (iconos)" \
    TRUE  "ttf-ubuntu-font-family" "Ubuntu Font" \
    TRUE  "noto-fonts"            "Noto Fonts" \
    TRUE  "noto-fonts-emoji"      "Emojis" \
    TRUE  "noto-fonts-cjk"        "Fuentes CJK (chino/japonés/coreano)" \
    TRUE  "nwg-look"              "GTK theme switcher" \
    TRUE  "cachyos-grub-theme"    "Tema GRUB CachyOS" \
    FALSE "sddm-silent-theme"     "Tema SDDM Silent (AUR)" \
    --separator=" " --width=600 --height=400)

  [ -z "$PKGS" ] && return

  # Separar nativos de AUR
  AUR_PKGS=""
  NAT_PKGS=""
  for p in $PKGS; do
    case $p in
      sddm-silent-theme) AUR_PKGS="$AUR_PKGS $p" ;;
      *) NAT_PKGS="$NAT_PKGS $p" ;;
    esac
  done

  [ -n "$NAT_PKGS" ] && sudo pacman -S --needed --noconfirm $NAT_PKGS
  [ -n "$AUR_PKGS" ] && paru -S --needed --noconfirm $AUR_PKGS
  log "Fuentes y temas instalados"
}

# ── Categoría: Shell y terminal ───────────────────────────────────────────────
install_shell() {
  step "Shell y terminal"
  PKGS=$(zenity --list --checklist \
    --title="Shell y terminal" \
    --column="✓" --column="Paquete" --column="Descripción" \
    TRUE  "fish"                  "Fish shell" \
    TRUE  "cachyos-fish-config"   "Config fish de CachyOS" \
    TRUE  "starship"              "Prompt Starship" \
    TRUE  "foot"                  "Terminal Foot" \
    TRUE  "kitty"                 "Terminal Kitty" \
    TRUE  "fastfetch"             "Neofetch moderno" \
    TRUE  "btop"                  "Monitor de sistema" \
    TRUE  "zoxide"                "cd inteligente" \
    TRUE  "ripgrep"               "grep más rápido" \
    TRUE  "lazygit"               "Git TUI" \
    TRUE  "micro"                 "Editor de texto terminal" \
    TRUE  "cava"                  "Visualizador de audio" \
    FALSE "blesh"                 "Bash Line Editor (AUR)" \
    --separator=" " --width=600 --height=500)

  [ -z "$PKGS" ] && return

  AUR_PKGS=""
  NAT_PKGS=""
  for p in $PKGS; do
    case $p in
      blesh) AUR_PKGS="$AUR_PKGS $p" ;;
      *) NAT_PKGS="$NAT_PKGS $p" ;;
    esac
  done

  [ -n "$NAT_PKGS" ] && sudo pacman -S --needed --noconfirm $NAT_PKGS
  [ -n "$AUR_PKGS" ] && paru -S --needed --noconfirm $AUR_PKGS
  log "Shell y terminal instalados"
}

# ── Categoría: Caelestia / Shell visual ──────────────────────────────────────
install_caelestia() {
  step "Caelestia Shell"
  PKGS=$(zenity --list --checklist \
    --title="Caelestia / Shell visual" \
    --column="✓" --column="Paquete" --column="Descripción" \
    TRUE  "quickshell-git"        "Framework shell Qt/QML (AUR)" \
    TRUE  "caelestia-shell-git"   "Caelestia shell (AUR)" \
    TRUE  "caelestia-cli-git"     "Caelestia CLI (AUR)" \
    TRUE  "caelestia-meta"        "Meta-paquete Caelestia (AUR)" \
    TRUE  "swww"                  "Wallpaper daemon (AUR)" \
    TRUE  "antigravity"           "Antigravity (AUR)" \
    TRUE  "waybar"                "Waybar (alternativa)" \
    TRUE  "mako"                  "Notificaciones" \
    TRUE  "rofi"                  "Launcher" \
    TRUE  "wlogout"               "Logout menu" \
    TRUE  "playerctl"             "Control de media" \
    --separator=" " --width=600 --height=500)

  [ -z "$PKGS" ] && return

  AUR_PKGS=""
  NAT_PKGS=""
  for p in $PKGS; do
    case $p in
      quickshell-git|caelestia-shell-git|caelestia-cli-git|caelestia-meta|swww|antigravity)
        AUR_PKGS="$AUR_PKGS $p" ;;
      *) NAT_PKGS="$NAT_PKGS $p" ;;
    esac
  done

  [ -n "$NAT_PKGS" ] && sudo pacman -S --needed --noconfirm $NAT_PKGS
  [ -n "$AUR_PKGS" ] && paru -S --needed --noconfirm $AUR_PKGS
  log "Caelestia instalado"
}

# ── Categoría: Desarrollo ─────────────────────────────────────────────────────
install_dev() {
  step "Herramientas de desarrollo"
  PKGS=$(zenity --list --checklist \
    --title="Desarrollo" \
    --column="✓" --column="Paquete" --column="Descripción" \
    TRUE  "git"                   "Control de versiones" \
    TRUE  "github-cli"            "GitHub CLI" \
    TRUE  "nodejs"                "Node.js" \
    TRUE  "npm"                   "NPM" \
    TRUE  "pnpm"                  "PNPM (alternativa a npm)" \
    FALSE "nvm"                   "Node Version Manager" \
    TRUE  "python"                "Python 3" \
    TRUE  "python-pip"            "PIP" \
    TRUE  "docker"                "Docker" \
    TRUE  "docker-compose"        "Docker Compose" \
    TRUE  "docker-buildx"         "Docker Buildx" \
    TRUE  "cmake"                 "CMake" \
    TRUE  "ninja"                 "Ninja build" \
    TRUE  "code"                  "VSCode" \
    TRUE  "vscodium-bin"          "VSCodium (AUR)" \
    TRUE  "vscodium-bin-marketplace" "VSCodium Marketplace (AUR)" \
    TRUE  "postman-bin"           "Postman (AUR)" \
    TRUE  "lazygit"               "LazyGit TUI" \
    TRUE  "meld"                  "Diff visual" \
    TRUE  "direnv"                "Env vars por directorio" \
    TRUE  "neovim"                "Neovim" \
    --separator=" " --width=600 --height=600)

  [ -z "$PKGS" ] && return

  AUR_PKGS=""
  NAT_PKGS=""
  for p in $PKGS; do
    case $p in
      vscodium-bin|vscodium-bin-marketplace|postman-bin)
        AUR_PKGS="$AUR_PKGS $p" ;;
      *) NAT_PKGS="$NAT_PKGS $p" ;;
    esac
  done

  [ -n "$NAT_PKGS" ] && sudo pacman -S --needed --noconfirm $NAT_PKGS
  [ -n "$AUR_PKGS" ] && paru -S --needed --noconfirm $AUR_PKGS

  # Docker habilitado
  if echo "$PKGS" | grep -q "docker"; then
    sudo systemctl enable --now docker
    sudo usermod -aG docker "$USER"
    log "Docker habilitado y usuario agregado al grupo docker"
  fi
  log "Herramientas de desarrollo instaladas"
}

# ── Categoría: Apps personales ────────────────────────────────────────────────
install_personal() {
  step "Apps personales"
  PKGS=$(zenity --list --checklist \
    --title="Apps personales" \
    --column="✓" --column="Paquete" --column="Descripción" \
    TRUE  "firefox"               "Firefox" \
    TRUE  "zen-browser-bin"       "Zen Browser (AUR)" \
    TRUE  "google-chrome"         "Google Chrome (AUR)" \
    TRUE  "brave-bin"             "Brave Browser (AUR)" \
    TRUE  "spotify"               "Spotify (AUR)" \
    TRUE  "spicetify-cli"         "Spicetify - temas Spotify (AUR)" \
    TRUE  "spicetify-marketplace-bin" "Spicetify Marketplace (AUR)" \
    TRUE  "discord"               "Discord" \
    TRUE  "thunar"                "Gestor de archivos Thunar" \
    TRUE  "vlc"                   "VLC" \
    TRUE  "mpv"                   "MPV" \
    TRUE  "qbittorrent"           "qBittorrent" \
    TRUE  "steam"                 "Steam" \
    TRUE  "flatpak"               "Flatpak" \
    TRUE  "bauh"                  "Gestor AUR/Flatpak (AUR)" \
    TRUE  "octopi"                "Gestor paquetes GUI" \
    TRUE  "scrcpy"                "Mirror Android en PC" \
    --separator=" " --width=600 --height=600)

  [ -z "$PKGS" ] && return

  AUR_PKGS=""
  NAT_PKGS=""
  for p in $PKGS; do
    case $p in
      zen-browser-bin|google-chrome|brave-bin|spotify|spicetify-cli|\
      spicetify-marketplace-bin|bauh)
        AUR_PKGS="$AUR_PKGS $p" ;;
      *) NAT_PKGS="$NAT_PKGS $p" ;;
    esac
  done

  [ -n "$NAT_PKGS" ] && sudo pacman -S --needed --noconfirm $NAT_PKGS
  [ -n "$AUR_PKGS" ] && paru -S --needed --noconfirm $AUR_PKGS
  log "Apps personales instaladas"
}

# ── Categoría: Dependencias de scripts ───────────────────────────────────────
install_script_deps() {
  step "Dependencias de scripts (montar_usb, sddm-config, etc)"
  PKGS=$(zenity --list --checklist \
    --title="Dependencias de scripts" \
    --column="✓" --column="Paquete" --column="Descripción" \
    TRUE  "ntfs-3g"              "Soporte NTFS (HDD Windows)" \
    TRUE  "exfatprogs"           "Soporte exFAT" \
    TRUE  "dosfstools"           "Soporte FAT32" \
    TRUE  "gvfs-mtp"             "MTP para Android en Thunar" \
    TRUE  "android-udev"         "Reglas udev para Android" \
    TRUE  "jmtpfs"               "MTP mount (AUR)" \
    TRUE  "zenity"               "Diálogos GUI para scripts" \
    TRUE  "mpv"                  "Reproductor video (preview SDDM)" \
    TRUE  "eog"                  "Visor de imágenes (preview SDDM)" \
    TRUE  "ffmpegthumbnailer"    "Miniaturas de video en Thunar" \
    --separator=" " --width=600 --height=450)

  [ -z "$PKGS" ] && return

  AUR_PKGS=""
  NAT_PKGS=""
  for p in $PKGS; do
    case $p in
      jmtpfs) AUR_PKGS="$AUR_PKGS $p" ;;
      *) NAT_PKGS="$NAT_PKGS $p" ;;
    esac
  done

  [ -n "$NAT_PKGS" ] && sudo pacman -S --needed --noconfirm $NAT_PKGS
  [ -n "$AUR_PKGS" ] && paru -S --needed --noconfirm $AUR_PKGS

  # Recargar udev para Android
  sudo udevadm control --reload-rules && sudo udevadm trigger
  log "Dependencias de scripts instaladas"
}

# ── Categoría: Seguridad / Red ────────────────────────────────────────────────
install_security() {
  step "Seguridad y red"
  PKGS=$(zenity --list --checklist \
    --title="Seguridad y red" \
    --column="✓" --column="Paquete" --column="Descripción" \
    FALSE "aircrack-ng"          "Auditoría WiFi" \
    FALSE "nmap"                 "Scanner de red" \
    FALSE "wireshark-qt"         "Análisis de paquetes" \
    FALSE "metasploit"           "Framework de pentesting" \
    FALSE "arp-scan"             "Scanner ARP" \
    TRUE  "ufw"                  "Firewall UFW" \
    TRUE  "openssh"              "SSH" \
    --separator=" " --width=600 --height=400)

  [ -z "$PKGS" ] && return
  sudo pacman -S --needed --noconfirm $PKGS

  if echo "$PKGS" | grep -q "ufw"; then
    sudo systemctl enable --now ufw
    sudo ufw enable
    log "UFW habilitado"
  fi
  log "Seguridad instalada"
}

# ── Instalar dotfiles ─────────────────────────────────────────────────────────
install_dotfiles() {
  step "Dotfiles"

  zenity --question \
    --title="Instalar dotfiles" \
    --text="¿Clonar y aplicar tus dotfiles desde GitHub?\n\ngithub.com/brixxdd/caelestia-dotfiles" \
    --ok-label="Sí, instalar" --cancel-label="Saltar"

  [ $? -ne 0 ] && return

  if [ -d "$DOTFILES_DIR" ]; then
    warn "~/caelestia ya existe, haciendo pull..."
    cd "$DOTFILES_DIR" && git pull
  else
    git clone https://github.com/brixxdd/caelestia-dotfiles.git "$DOTFILES_DIR"
  fi

  # Crear symlinks igual que el setup original
  CONFIGS=(btop fastfetch fish foot hypr micro spicetify thunar uwsm vscode)
  for cfg in "${CONFIGS[@]}"; do
    if [ -d "$DOTFILES_DIR/$cfg" ]; then
      ln -sf "$DOTFILES_DIR/$cfg" "$HOME/.config/$cfg"
      log "Symlink creado: ~/.config/$cfg → $DOTFILES_DIR/$cfg"
    fi
  done

  # Starship
  [ -f "$DOTFILES_DIR/starship.toml" ] && \
    ln -sf "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"

  # Scripts personales
  mkdir -p "$SCRIPTS_DIR"
  if [ -d "$DOTFILES_DIR/scripts" ]; then
    cp "$DOTFILES_DIR/scripts/"* "$SCRIPTS_DIR/"
    chmod +x "$SCRIPTS_DIR/"*
    log "Scripts instalados en $SCRIPTS_DIR"
  fi

  # SDDM tema configs
  if [ -d "$DOTFILES_DIR/sddm" ]; then
    zenity --question \
      --text="¿Instalar configuración del tema SDDM?" \
      --ok-label="Sí" --cancel-label="No"
    if [ $? -eq 0 ]; then
      sudo cp -r "$DOTFILES_DIR/sddm/configs/"* /usr/share/sddm/themes/silent/configs/ 2>/dev/null
      sudo cp -r "$DOTFILES_DIR/sddm/backgrounds/"* /usr/share/sddm/themes/silent/backgrounds/ 2>/dev/null
      log "Config SDDM restaurada"
    fi
  fi

  log "Dotfiles instalados"
}

# ── Habilitar servicios ───────────────────────────────────────────────────────
enable_services() {
  step "Servicios del sistema"

  SERVICES=$(zenity --list --checklist \
    --title="Servicios a habilitar" \
    --column="✓" --column="Servicio" --column="Descripción" \
    TRUE  "NetworkManager"        "Red" \
    TRUE  "bluetooth"             "Bluetooth" \
    TRUE  "sddm"                  "Display manager" \
    TRUE  "power-profiles-daemon" "Perfiles de energía" \
    FALSE "docker"                "Docker" \
    FALSE "ufw"                   "Firewall" \
    --separator=" " --width=500 --height=400)

  [ -z "$SERVICES" ] && return

  for svc in $SERVICES; do
    sudo systemctl enable --now "$svc" && log "$svc habilitado"
  done
}

# ── Resumen final ─────────────────────────────────────────────────────────────
finish() {
  zenity --info \
    --title="✅ Instalación completa" \
    --text="Tu setup ha sido instalado.\n\nRecuerda:\n• Reinicia la sesión para aplicar cambios de grupos (docker)\n• Configura Spicetify: spicetify backup apply\n• Activa el tema SDDM en /etc/sddm.conf\n• Verifica los symlinks en ~/.config/\n\n¡Bienvenido de vuelta a tu sistema!" \
    --width=400
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  check_base
  welcome

  CATEGORIES=$(zenity --list --checklist \
    --title="¿Qué quieres instalar?" \
    --text="Selecciona las categorías:" \
    --column="✓" --column="Categoría" \
    TRUE  "Sistema base" \
    TRUE  "Fuentes y temas" \
    TRUE  "Shell y terminal" \
    TRUE  "Caelestia Shell" \
    TRUE  "Desarrollo" \
    TRUE  "Apps personales" \
    TRUE  "Dependencias de scripts" \
    FALSE "Seguridad y red" \
    TRUE  "Dotfiles" \
    TRUE  "Servicios" \
    --separator="|" --width=450 --height=520)

  [ -z "$CATEGORIES" ] && exit 0

  echo "$CATEGORIES" | grep -q "Sistema base"        && install_base
  echo "$CATEGORIES" | grep -q "Fuentes y temas"     && install_fonts_themes
  echo "$CATEGORIES" | grep -q "Shell y terminal"    && install_shell
  echo "$CATEGORIES" | grep -q "Caelestia Shell"     && install_caelestia
  echo "$CATEGORIES" | grep -q "Desarrollo"          && install_dev
  echo "$CATEGORIES" | grep -q "Apps personales"     && install_personal
  echo "$CATEGORIES" | grep -q "Dependencias"        && install_script_deps
  echo "$CATEGORIES" | grep -q "Seguridad"           && install_security
  echo "$CATEGORIES" | grep -q "Dotfiles"            && install_dotfiles
  echo "$CATEGORIES" | grep -q "Servicios"           && enable_services

  finish
}

main
