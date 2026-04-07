#!/bin/bash

# ================================================================
#   OXH BRUTALIST INSTALLER v6.5 (clean, safe, modular)
# ================================================================

set -e

# ---------------- CONFIG ----------------
DRY_RUN=false
PROFILE=""
LOG_FILE="install.log"

# ---------------- FLAGS ----------------
for arg in "$@"; do
  case $arg in
    --dry-run) DRY_RUN=true ;;
    --profile=*) PROFILE="${arg#*=}" ;;
  esac
done

# ---------------- LOGGING ----------------
exec > >(tee -i "$LOG_FILE")
exec 2>&1

# ---------------- HELPERS ----------------
run() {
  if $DRY_RUN; then
    echo "[DRY] $*"
  else
    eval "$@"
  fi
}

info() { echo -e "\e[34m[>]\e[0m $1"; }
success() { echo -e "\e[32m[✓]\e[0m $1"; }
warn() { echo -e "\e[33m[!]\e[0m $1"; }
error() { echo -e "\e[31m[✗]\e[0m $1"; }

# ---------------- CHECKS ----------------
[[ $EUID -eq 0 ]] && { error "Do not run as root"; exit 1; }

if ! ping -c 1 archlinux.org &>/dev/null; then
  error "No internet connection"
  exit 1
fi

# ---------------- PROFILE ----------------
if [[ -z "$PROFILE" ]]; then
  echo "[1] PC"
  echo "[2] Laptop"
  read -p "Select profile: " choice
  [[ "$choice" == "1" ]] && PROFILE="pc"
  [[ "$choice" == "2" ]] && PROFILE="laptop"
fi

[[ -z "$PROFILE" ]] && { error "Invalid profile"; exit 1; }

info "Selected profile: $PROFILE"

# ---------------- SUDO KEEP ALIVE ----------------
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# ================================================================
# PACKAGES
# ================================================================

PACMAN_PKGS=(
  hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
  qt5-wayland qt6-wayland qt5-quickcontrols qt5-quickcontrols2 qt5-graphicaleffects
  polkit-kde-agent hypridle hyprlock hyprpaper
  sddm waybar dunst libnotify
  alacritty zsh zsh-completions
  pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber pavucontrol pamixer playerctl
  bluez bluez-utils blueman
  networkmanager network-manager-applet
  fastfetch yazi btop cava eza bat fzf fd ripgrep jq p7zip rsync git curl wget unzip
  wl-clipboard wtype grim slurp
  noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-font-awesome ttf-jetbrains-mono-nerd
  python-dateutil
)

AUR_PKGS=(
  rofi-wayland ttf-terminus-font hyprshot wlogout gcalcli
)

install_pkgs() {
  local manager="$1"; shift
  for pkg in "$@"; do
    if pacman -Qq "$pkg" &>/dev/null; then
      success "$pkg already installed"
    else
      run "$manager -S --noconfirm --needed $pkg" || warn "Failed: $pkg"
    fi
  done
}

# Install yay if missing
if ! command -v yay &>/dev/null; then
  info "Installing yay..."
  run "sudo pacman -S --needed --noconfirm base-devel git"
  run "git clone https://aur.archlinux.org/yay.git /tmp/yay-build"
  run "cd /tmp/yay-build && makepkg -si --noconfirm"
fi

info "Installing packages..."
install_pkgs "sudo pacman" "${PACMAN_PKGS[@]}"
install_pkgs "yay" "${AUR_PKGS[@]}"

# ================================================================
# SERVICES
# ================================================================

info "Enabling services"

services=(sddm NetworkManager bluetooth)
for s in "${services[@]}"; do
  run "sudo systemctl enable $s"
done

# ================================================================
# DOTFILES DEPLOY (SAFE)
# ================================================================

info "Deploying configs (common + variant)"

mkdir -p "$HOME/.config"

run "rsync -ah configs/common/ $HOME/.config/"
run "rsync -ah configs/variants/$PROFILE/ $HOME/.config/"

run "find $HOME/.config -name '*.sh' -exec chmod +x {} +"

# ================================================================
# ZSH SETUP
# ================================================================

if [[ "$SHELL" != "$(command -v zsh)" ]]; then
  info "Setting zsh as default shell"
  run "chsh -s $(command -v zsh)"
fi

ZINIT_HOME="$HOME/.local/share/zinit/zinit.git"
if [[ ! -d "$ZINIT_HOME" ]]; then
  info "Installing Zinit"
  run "git clone https://github.com/zdharma-continuum/zinit.git $ZINIT_HOME"
fi

# ================================================================
# GPU DETECTION
# ================================================================

if lspci | grep -qi amd; then
  warn "AMD GPU detected"
fi

# ================================================================
# GCALCLI SETUP
# ================================================================

read -p "Setup Google Calendar integration now? [y/N]: " gcal
if [[ "$gcal" =~ ^[Yy]$ ]]; then
  gcalcli list
fi

# ================================================================
# WALLPAPER
# ================================================================

if [[ -f "assets/wallpaper.jpg" ]]; then
  run "sudo mkdir -p /usr/share/backgrounds"
  run "sudo cp assets/wallpaper.jpg /usr/share/backgrounds/oxh-wallpaper.jpg"
fi

# ================================================================
# SDDM THEME
# ================================================================

SDDM_THEME_DIR="/usr/share/sddm/themes/oxh-sddm"

if [[ -d "system/sddm-theme" ]]; then
  run "sudo mkdir -p $SDDM_THEME_DIR"
  run "sudo cp -r system/sddm-theme/* $SDDM_THEME_DIR/"

  if [[ ! -f /etc/sddm.conf.d/theme.conf ]]; then
    run "echo -e '[Theme]\nCurrent=oxh-sddm' | sudo tee /etc/sddm.conf.d/theme.conf"
  fi
fi

# ================================================================
# GTK SETTINGS
# ================================================================

mkdir -p "$HOME/.config/gtk-3.0"
mkdir -p "$HOME/.config/gtk-4.0"

cat > "$HOME/.config/gtk-3.0/settings.ini" <<EOF
[Settings]
gtk-application-prefer-dark-theme=1
gtk-cursor-theme-name=Adwaita
gtk-icon-theme-name=Adwaita
EOF

cp "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"

# ================================================================
# DONE
# ================================================================

success "Installation complete"
echo "Reboot recommended"
