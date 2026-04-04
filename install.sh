#!/bin/bash
set -e
DOTFILES="$HOME/.dotfiles"
mkdir -p ~/.config
ln -sf "$DOTFILES/nvim" ~/.config/nvim
ln -sf "$DOTFILES/starship.toml" ~/.config/starship.toml
ln -sf "$DOTFILES/bashrc" ~/.bashrc
echo "Done!"
