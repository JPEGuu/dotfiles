#!/bin/bash

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

setup_symlink() {
    local source_file="$1"
    local target_file="$2"
    local target_dir=$(dirname "$target_file")

    # Create target directory if it doesn't exist
    if [ ! -d "$target_dir" ]; then
        echo "📂 Creating directory $target_dir"
        mkdir -p "$target_dir"
    fi

    # Backup if it exists and is not a symlink
    if [ -e "$target_file" ] && [ ! -L "$target_file" ]; then
        echo "📦 Backing up existing $target_file to $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
        mv "$target_file" "$BACKUP_DIR/"
    elif [ -L "$target_file" ]; then
        echo "🔗 Removing existing symlink $target_file"
        rm "$target_file"
    fi

    echo "🚀 Linking $source_file to $target_file"
    ln -s "$source_file" "$target_file"
}

# Link shell configs
setup_symlink "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc"
setup_symlink "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"

# Link tool configs
setup_symlink "$DOTFILES_DIR/.config/zellij" "$HOME/.config/zellij"
setup_symlink "$DOTFILES_DIR/.config/nvim" "$HOME/.config/nvim"
setup_symlink "$DOTFILES_DIR/.config/yazi" "$HOME/.config/yazi"

echo "✅ Installation complete! Please restart your shell."