#!/bin/bash
set -e
DOTFILES="$HOME/.dotfiles"
mkdir -p ~/.config

# starship 설치
curl -sS https://starship.rs/install.sh | sh

# nvim 설치
sudo snap install nvim --classic

# Install Basic Packages
sudo apt install -y git curl wget unzip build-essential ripgrep fd-find

# symlink
ln -sf "$DOTFILES/nvim" ~/.config/nvim
ln -sf "$DOTFILES/starship.toml" ~/.config/starship.toml
ln -sf "$DOTFILES/bashrc" ~/.bashrc

echo "Done!"
ln -sf "$DOTFILES/gitconfig" ~/.gitconfig
