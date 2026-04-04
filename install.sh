#!/bin/bash
set -e
DOTFILES="$HOME/.dotfiles"
mkdir -p ~/.config

# starship 설치
curl -sS https://starship.rs/install.sh | sh

# symlink
ln -sf "$DOTFILES/nvim" ~/.config/nvim
ln -sf "$DOTFILES/starship.toml" ~/.config/starship.toml
ln -sf "$DOTFILES/bashrc" ~/.bashrc

echo "Done!"
