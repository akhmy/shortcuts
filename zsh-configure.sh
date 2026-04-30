#!/bin/bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

attempt() {
    echo -e "${BLUE}$1${NC}"
}
success() {
    echo -e "${GREEN}$1${NC}"
}
warn() {
    echo -e "${YELLOW}$1${NC}"
}
error() {
    echo -e "${RED}$1${NC}" >&2
    exit 1
}

ROOT_FLAG=false

while getopts "r" opt; do
    case $opt in
        r)
            ROOT_FLAG=true
            ;;
        *)
            error "Unknown flag: -$opt"
            ;;
    esac
done

if [[ $EUID -eq 0 && $ROOT_FLAG == false ]]
then
    warn "Running as root is not recommended. To configure Zsh for a root user, run this script with '-r' flag."
    exit 1
fi

ZSHRC="$HOME/.zshrc"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"


attempt "Updating package lists..."
sudo apt-get update -q
success "Package lists updated."


attempt "Installing Zsh..."
sudo apt-get install -y zsh
success "Zsh installed."


attempt "Installing Oh My Zsh..."

if [[ -d "$HOME/.oh-my-zsh" ]]
then
    warn "Oh My Zsh is already installed. Skipping installation."
else
    RUNZSH=no CHSH=no sh -c \
        "$(curl -fsSL \
            https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    success "Oh My Zsh installed."
fi

ZSH_AUTOSUGGESTIONS_DIR="$ZSH_CUSTOM/plugins/zsh-autosuggestions"


attempt "Installing zsh-autosuggestions plugin..."

if [[ -d "$ZSH_AUTOSUGGESTIONS_DIR" ]]
then
    warn "zsh-autosuggestions is already installed. Skipping installation."
else
    git clone --depth=1 \
        https://github.com/zsh-users/zsh-autosuggestions \
            "$ZSH_AUTOSUGGESTIONS_DIR"
    success "zsh-autosuggestions installed."
fi

ZSH_SYNTAX_HIGHLIGHTING_DIR="$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"


attempt "Installing zsh-syntax-highlighting plugin..."

if [[ -d "$ZSH_SYNTAX_HIGHLIGHTING_DIR" ]]
then
    warn "zsh-syntax-highlighting is already installed. Skipping installation."
else
    git clone --depth=1 \
        https://github.com/zsh-users/zsh-syntax-highlighting \
            "$ZSH_SYNTAX_HIGHLIGHTING_DIR"
    success "zsh-syntax-highlighting installed."
fi

P10K_DIR="$ZSH_CUSTOM/themes/powerlevel10k"


attempt "Installing Powerlevel10k theme..."

if [[ -d "$P10K_DIR" ]]
then
    warn "Powerlevel10k theme is already installed. Skipping installation."
else
    git clone --depth=1 \
        https://github.com/romkatv/powerlevel10k \
            "$P10K_DIR"
    success "Powerlevel10k theme installed."
fi


attempt "Configuring .zshrc..."

if [[ -f "$ZSHRC" ]]
then
    warn ".zshrc already exists. Backing it up to .zshrc.bak.$(date +%Y%m%d_%H%M%S)"
    cp "$ZSHRC" "$ZSHRC.bak"
    success "Backup created at .zshrc.bak"
fi

sed -i 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' "$ZSHRC"

if grep -q "^plugins=" "$ZSHRC"
then
    sed -i 's|^plugins=.*|plugins=(git zsh-autosuggestions zsh-syntax-highlighting)|' "$ZSHRC"
else
    echo 'plugins=(git zsh-autosuggestions zsh-syntax-highlighting)' >> "$ZSHRC"
fi

success ".zshrc configured."


attempt "Changing default shell to Zsh..."

ZSH_PATH="$(which zsh)"

if [[ "$SHELL" == "$ZSH_PATH" ]]
then
    warn "Default shell is already Zsh. Skipping."
else
    chsh -s "$ZSH_PATH" "$USER"
    success "Default shell changed to Zsh. Please log out and log back in for the change to take effect."
fi