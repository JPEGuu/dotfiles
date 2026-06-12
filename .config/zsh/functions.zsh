# --- Dotfiles Management ---
dotfiles-adopt() {
    if [ -z "$1" ]; then
        echo "Usage: dotfiles-adopt <config-name>" >&2
        echo "  e.g. dotfiles-adopt bottom" >&2
        return 1
    fi

    local name="$1"
    local src="$HOME/.config/$name"
    local dotfiles_dir="${DOTFILES:-$HOME/dotfiles}"
    local dest="$dotfiles_dir/.config/$name"

    if [ ! -e "$src" ]; then
        echo "❌ $src does not exist." >&2
        return 1
    fi
    if [ -L "$src" ]; then
        echo "✅ $src is already a symlink. No action needed." >&2
        return 0
    fi
    if [ -e "$dest" ]; then
        echo "❌ $dest already exists in dotfiles. Remove it first if you want to re-adopt." >&2
        return 1
    fi

    mv "$src" "$dest"
    ln -s "$dest" "$src"
    echo "🔗 Adopted: $src -> $dest"

    (
        cd "$dotfiles_dir" || return
        git add ".config/$name"
        git commit -m "Adopt: $name"
        echo "✅ Committed to dotfiles."
    )
}

# --- npm Global Package Management ---
if command -v npm > /dev/null 2>&1; then
    _sync_npm_global() {
        local message="$1"
        local dotfiles_dir="${DOTFILES:-$HOME/dotfiles}"
        npm list -g --depth=0 --parseable 2>/dev/null \
            | tail -n +2 \
            | xargs -I{} basename {} \
            > "$dotfiles_dir/npm-global.txt"
        (
            cd "$dotfiles_dir" || return
            if [[ -n $(git status --porcelain npm-global.txt) ]]; then
                git add npm-global.txt && git commit -m "$message"
            fi
        )
    }
    function npmg-in() { npm install -g "$@"   && _sync_npm_global "npm-global install: $*"; }
    function npmg-rm() { npm uninstall -g "$@" && _sync_npm_global "npm-global remove: $*"; }
fi

# --- Composer Global Package Management ---
if command -v composer > /dev/null 2>&1; then
    _sync_composer_global() {
        local message="$1"
        local dotfiles_dir="${DOTFILES:-$HOME/dotfiles}"
        composer global info --format=json 2>/dev/null \
            | jq -r '.installed[].name' \
            > "$dotfiles_dir/composer-global.txt"
        (
            cd "$dotfiles_dir" || return
            if [[ -n $(git status --porcelain composer-global.txt) ]]; then
                git add composer-global.txt && git commit -m "$message"
            fi
        )
    }
    function composerg-in() { composer global require "$@" && _sync_composer_global "composer-global install: $*"; }
    function composerg-rm() { composer global remove "$@"  && _sync_composer_global "composer-global remove: $*"; }
fi

# --- Cargo Package Management ---
if command -v cargo > /dev/null 2>&1; then
    _sync_cargo() {
        local message="$1"
        local dotfiles_dir="${DOTFILES:-$HOME/dotfiles}"
        cargo install --list 2>/dev/null \
            | grep -E '^[a-z]' \
            | awk '{print $1}' \
            > "$dotfiles_dir/cargo-packages.txt"
        (
            cd "$dotfiles_dir" || return
            if [[ -n $(git status --porcelain cargo-packages.txt) ]]; then
                git add cargo-packages.txt && git commit -m "$message"
            fi
        )
    }
    function cargo-in() { cargo install "$@"   && _sync_cargo "cargo install: $*"; }
    function cargo-rm() { cargo uninstall "$@" && _sync_cargo "cargo remove: $*"; }
fi

# --- Arch Linux / Pacman Functions (Container Side) ---
if command -v pacman > /dev/null 2>&1; then
    _sync_pkglist() {
        local message="$1"
        local dotfiles_dir="${DOTFILES:-$HOME/dotfiles}"

        echo "📄 Updating pkglist.txt..."
        pacman -Qqe > "$dotfiles_dir/pkglist.txt"

        (
            cd "$dotfiles_dir" || exit
            if [[ -n $(git status --porcelain pkglist.txt) ]]; then
                echo "📦 Changes detected. Committing locally..."
                git add pkglist.txt
                git commit -m "$message"
                echo "✅ Changes committed to $dotfiles_dir"
            else
                echo "ℹ️  No changes in package list."
            fi
        )
    }

function pacin() {
    sudo pacman -S "$@" && _sync_pkglist "Install: $*"
}

function pacrm() {
    sudo pacman -Rns "$@" && _sync_pkglist "Remove: $*"
}
fi
