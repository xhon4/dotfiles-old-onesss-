#!/bin/bash

# --- COLORES ---
BOLD="$(tput bold)"
RED="$(tput setaf 1)"
GREEN="$(tput setaf 2)"
YELLOW="$(tput setaf 3)"
BLUE="$(tput setaf 4)"
RESET="$(tput sgr0)"

# --- 1. VALIDACIÓN INICIAL ---
clear
echo "${BLUE}${BOLD}OXH BRUTALIST INSTALLER v4.0 [DESKTOP]${RESET}"
echo "-------------------------------------------------------"
echo -e "${YELLOW}[!] Target:${RESET} ~/.config/ <--- configs/pc/"
echo -e "${RED}${BOLD}[!] WARNING:${RESET} This will overwrite existing configurations."
read -p "Proceed? [y/N]: " confirm
[[ ! "$confirm" =~ ^[Yy]$ ]] && echo "Aborted." && exit 1

# Sudo keep-alive (Principio de persistencia de procesos - OS M4)
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# --- 2. ACTUALIZACIÓN Y AUR HELPER ---
echo -e "\n${GREEN}[1/7] Synchronizing system...${RESET}"
sudo pacman -Syu --noconfirm

if ! command -v yay &> /dev/null; then
    echo "Installing yay..."
    sudo pacman -S --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    (cd /tmp/yay && makepkg -si --noconfirm)
fi

# --- 3. LISTA DE PAQUETES ---
PACMAN_PKGS=(
    "alacritty" "waybar" "fastfetch" "yazi" "zsh" "jq" "p7zip" "eza" "bat" 
    "cava" "btop" "dunst" "pamixer" "playerctl" "hypridle" "hyprlock" 
    "hyprpaper" "sddm" "noto-fonts" "noto-fonts-cjk" "noto-fonts-emoji" 
    "ttf-font-awesome" "ttf-jetbrains-mono-nerd" "rsync" "wtype" "wl-clipboard"
)

AUR_PKGS=(
    "awww" "rofi-wayland" "ttf-terminus-font"
)

# --- 4. MOTOR DE INSTALACIÓN ---
install_logic() {
    local manager=$1
    shift
    local list=("$@")
    for pkg in "${list[@]}"; do
        if ! pacman -Qq "$pkg" &> /dev/null; then
            echo "  -> Installing $pkg..."
            $manager -S --noconfirm "$pkg"
        else
            echo "  -> [OK] $pkg is present."
        fi
    done
}

echo -e "\n${GREEN}[2/7] Installing Pacman packages...${RESET}"
install_logic "sudo pacman" "${PACMAN_PKGS[@]}"

echo -e "\n${GREEN}[3/7] Installing AUR packages...${RESET}"
install_logic "yay" "${AUR_PKGS[@]}"

# --- 5. DESPLIEGUE DE DOTFILES (The Core) ---
echo -e "\n${GREEN}[4/7] Deploying configs from configs/pc/...${RESET}"
mkdir -p "$HOME/.config"
# Usamos rsync para una copia exacta y limpia
rsync -avh --delete configs/pc/ "$HOME/.config/"

# --- 6. CONFIGURACIÓN DE SHELL ---
echo -e "\n${GREEN}[5/7] Configuring Zsh & Powerlevel10k...${RESET}"
[[ "$SHELL" != "/usr/bin/zsh" ]] && chsh -s "$(which zsh)"
# Copiamos desde la raíz del repo al HOME del usuario
[[ -f ".zshrc" ]] && cp .zshrc "$HOME/"
[[ -f ".p10k.zsh" ]] && cp .p10k.zsh "$HOME/"

# --- 7. ASSETS Y SISTEMA ---
echo -e "\n${GREEN}[6/7] Deploying Assets & SDDM...${RESET}"

# Wallpaper (Desde la nueva carpeta assets)
sudo mkdir -p /usr/share/backgrounds
if [[ -f "assets/wallpaper.jpg" ]]; then
    sudo cp assets/wallpaper.jpg /usr/share/backgrounds/y8yxlx.jpg
    echo "  -> Wallpaper deployed."
fi

# SDDM Theme (Desde la nueva carpeta system)
if [[ -d "system/sddm-theme" ]]; then
    sudo mkdir -p /usr/share/sddm/themes/oxh-sddm
    sudo cp -r system/sddm-theme/* /usr/share/sddm/themes/oxh-sddm/
    sudo systemctl enable sddm.service
    echo "  -> SDDM theme configured."
fi

# --- 8. PERMISOS Y FINALIZACIÓN ---
echo -e "\n${GREEN}[7/7] Finalizing permissions...${RESET}"
find "$HOME/.config" -name "*.sh" -exec chmod +x {} +

echo -e "\n${BLUE}${BOLD}======================================================="
echo "${GREEN}  DESKTOP DEPLOYMENT SUCCESSFUL!"
echo "${BLUE}=======================================================${RESET}"
echo "Reboot is recommended to apply SDDM and Shell changes."
