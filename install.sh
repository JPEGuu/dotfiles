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
        # Check if it already points to the correct place
        local current_target=$(readlink -f "$target_file")
        if [ "$current_target" == "$source_file" ]; then
            echo "✅ $target_file is already correctly linked."
            return
        fi
        echo "🔗 Removing existing symlink $target_file"
        rm "$target_file"
    fi

    echo "🚀 Linking $source_file to $target_file"
    ln -s "$source_file" "$target_file"
}

echo "🛠️  Starting Dotfiles Installation..."

# Link shell configs
setup_symlink "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc"
setup_symlink "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"

# Link all configs in .config
if [ -d "$DOTFILES_DIR/.config" ]; then
    for config in "$DOTFILES_DIR/.config"/*; do
        name=$(basename "$config")
        setup_symlink "$config" "$HOME/.config/$name"
    done
fi

echo "✅ Installation complete! Please restart your shell."
