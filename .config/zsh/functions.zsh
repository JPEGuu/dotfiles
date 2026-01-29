# --- Gemini Wrapper ---
# Interactive session resume with fzf. Supports 'gemini new' shortcut.
gemini() {
    # Shortcut: 'gemini new' starts a new session immediately
    if [ "$1" = "new" ]; then
        shift
        command gemini "$@"
        return
    fi

    if [ $# -eq 0 ]; then
        local new_label="🆕 Start New Session"
        # Get session list, strip headers
        local sessions=$(command gemini --list-sessions | grep -E '^[[:space:]]+[0-9]+\.')

        # Prepend "New Session" option and show in fzf
        local selected=$(echo -e "$new_label\n$sessions" | fzf --height 40% --reverse --header "Select session or action")

        if [[ "$selected" == "$new_label" ]]; then
            echo "✨ Starting new session..."
            command gemini
        elif [[ -n "$selected" ]]; then
            # Extract ID and resume
            local id=$(echo "$selected" | sed -E 's/^[[:space:]]+([0-9]+)\..*/\1/')
            echo "🔄 Resuming session #$id..."
            command gemini --resume "$id"
        fi
    else
        command gemini "$@"
    fi
}

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
