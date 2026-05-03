#!/bin/bash

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
CLEANUP_LOG="$HOME/.dotfiles_cleanup_$(date +%Y%m%d_%H%M%S).log"

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

cleanup_stale_symlinks() {
    local removed=0

    for link in "$HOME/.config"/* "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [ -L "$link" ] && [ ! -e "$link" ]; then
            local target
            target=$(readlink "$link")
            # Only remove symlinks that were managed by dotfiles
            if [[ "$target" == "$DOTFILES_DIR/"* ]]; then
                echo "ln -s $(printf '%q' "$target") $(printf '%q' "$link")" >> "$CLEANUP_LOG"
                echo "🗑️  Removing stale symlink: $link -> $target"
                rm "$link"
                removed=$((removed + 1))
            fi
        fi
    done

    if [ "$removed" -gt 0 ]; then
        echo "📋 Cleanup log saved to $CLEANUP_LOG (run it to restore removed symlinks)"
    fi
}

echo "🛠️  Starting Dotfiles Installation..."

cleanup_stale_symlinks

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

# Install packages from pkglist.txt
if command -v pacman >/dev/null 2>&1 && [ -f "$DOTFILES_DIR/pkglist.txt" ]; then
    echo "📦 Installing packages from pkglist.txt..."
    if sudo pacman -Syu --needed --noconfirm - < "$DOTFILES_DIR/pkglist.txt"; then
        echo "✅ Packages installed successfully."
    else
        echo "❌ ERROR: Failed to install packages." >&2
        exit 1
    fi
fi

# Ensure nvm is installed and loaded
export NVM_DIR="$HOME/.config/nvm"
if [ ! -d "$NVM_DIR" ]; then
    echo "📦 Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi

# Load nvm
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Ensure Node.js and npm are installed via nvm
if command -v nvm >/dev/null 2>&1; then
    echo "📦 Ensuring Node.js (LTS) is installed via nvm..."
    nvm install --lts
    nvm use --lts
    nvm alias default 'lts/*'
else
    echo "❌ ERROR: Failed to load nvm. Skipping npm package installation." >&2
fi

# Install npm global packages
if command -v npm >/dev/null 2>&1 && [ -f "$DOTFILES_DIR/npm-global.txt" ]; then
    echo "📦 Installing npm global packages..."
    if xargs npm install -g < "$DOTFILES_DIR/npm-global.txt"; then
        echo "✅ npm global packages installed."
    else
        echo "⚠️  WARNING: Some npm global packages failed to install." >&2
    fi
fi

# Install composer global packages
if command -v composer >/dev/null 2>&1 && [ -f "$DOTFILES_DIR/composer-global.txt" ]; then
    echo "📦 Installing composer global packages..."
    if xargs composer global require < "$DOTFILES_DIR/composer-global.txt"; then
        echo "✅ Composer global packages installed."
    else
        echo "⚠️  WARNING: Some composer global packages failed to install." >&2
    fi
fi

# Install cargo packages
if command -v cargo >/dev/null 2>&1 && [ -f "$DOTFILES_DIR/cargo-packages.txt" ]; then
    echo "📦 Installing cargo packages..."
    # Ensure a default rust toolchain is set before trying to install
    if command -v rustup >/dev/null 2>&1 && ! rustc --version >/dev/null 2>&1; then
        echo "📦 Setting default Rust toolchain to stable..."
        rustup default stable
    fi

    while IFS= read -r line || [ -n "$line" ]; do
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        # shellcheck disable=SC2086
        if ! cargo install $line; then
            echo "⚠️  WARNING: Failed to install: $line" >&2
        fi
    done < "$DOTFILES_DIR/cargo-packages.txt"
    echo "✅ Cargo packages installation process completed."
fi

# Link rtk global config
setup_symlink "$DOTFILES_DIR/.config/rtk" "$HOME/.config/rtk"

# Link Claude Code global config
setup_symlink "$DOTFILES_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
setup_symlink "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"
setup_symlink "$DOTFILES_DIR/claude/commands" "$HOME/.claude/commands"
setup_symlink "$DOTFILES_DIR/claude/agents" "$HOME/.claude/agents"

# Link Gemini CLI global config
setup_symlink "$DOTFILES_DIR/gemini/GEMINI.md" "$HOME/.gemini/GEMINI.md"
setup_symlink "$DOTFILES_DIR/gemini/skills" "$HOME/.gemini/skills"
setup_symlink "$DOTFILES_DIR/gemini/settings.json" "$HOME/.gemini/settings.json"

echo "✅ Installation complete! Please restart your shell."
