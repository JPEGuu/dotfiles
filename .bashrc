# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
for dir in "$HOME/.local/bin" "$HOME/bin"; do
    if [ -d "$dir" ] && [[ ":$PATH:" != *":$dir:"* ]]; then
        PATH="$dir:$PATH"
    fi
done
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
alias dotpush='(cd ~/dotfiles && git push)'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias diff='diff --color=auto'

# Better history management
export HISTCONTROL=ignoreboth
export HISTSIZE=10000
export HISTFILESIZE=20000
shopt -s histappend # Append to history instead of overwriting

if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc

# Enter Arch when login
if command -v distrobox > /dev/null 2>&1; then
    if [ -t 1 ] && [ -z "$DISTROBOX_ENTERD" ]; then
        distrobox enter arch-dev
    fi
fi

# Pacman
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
        # -Rns : 設定ファイル(n)と、不要になった依存パッケージ(s)もまとめて消す
        sudo pacman -Rns "$@" && _sync_pkglist "Remove: $*"
    }
fi
