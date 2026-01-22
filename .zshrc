# .zshrc

# --- Global Definitions ---
# Source global definitions if they exist (common in RHEL/CentOS/AlmaLinux)
if [ -f /etc/zshrc ]; then
    . /etc/zshrc
fi

# --- Environment Variables ---
for dir in "$HOME/.local/bin" "$HOME/bin"; do
    if [ -d "$dir" ] && [[ ":$PATH:" != *":$dir:"* ]]; then
        PATH="$dir:$PATH"
    fi
done
export PATH

# --- Zsh Configuration ---
# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=20000
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

# Completion
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' # Case insensitive
zstyle ':completion:*' menu select

# Prompt (Simple & Clean)
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats '(%b)'
setopt PROMPT_SUBST
PROMPT='%F{cyan}%n%f@%F{green}%m%f:%F{blue}%~%f ${vcs_info_msg_0_} %# '

# --- Aliases ---
alias dotpush='(cd ~/dotfiles && git push)'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# --- Distrobox Auto-Enter (Host Side) ---
# Enter Arch when login if strictly interactive and not already inside
if command -v distrobox > /dev/null 2>&1; then
    if [ -t 1 ] && [ -z "$DISTROBOX_ENTERD" ]; then
        # Check if we are already in the target container to avoid loops logic if env var fails
        # But DISTROBOX_ENTERD is standard.
        distrobox enter arch-dev
    fi
fi

# --- Arch Linux / Pacman Functions (Container Side) ---
if command -v pacman > /dev/null 2>&1; then
    _sync_pkglist() {
        local message="$1"
        local dotfiles_dir="$HOME/dotfiles"
        
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

# Load extra configs
if [ -d ~/.zshrc.d ]; then
    for rc in ~/.zshrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
