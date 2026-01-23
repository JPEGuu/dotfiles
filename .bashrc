# .bashrc

# --- AlmaLinux / RHEL / Global Settings ---
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# --- Variables ---
export DOTFILES="$HOME/dotfiles"

# --- Zsh Auto-Start ---
# If Zsh is available, launch it immediately.
if [ -t 1 ] && command -v zsh >/dev/null 2>&1; then
    exec zsh
fi

# =================================================================
# Fallback Settings (Used only if Zsh is NOT installed)
# =================================================================

# User specific environment
for dir in "$HOME/.local/bin" "$HOME/bin"; do
    if [ -d "$dir" ] && [[ ":$PATH:" != *":$dir:"* ]]; then
        PATH="$dir:$PATH"
    fi
done
export PATH

# --- Modular Configs ---
# Aliases
if [ -f "$HOME/.config/shell/aliases.sh" ]; then
    source "$HOME/.config/shell/aliases.sh"
fi

# Enter Arch when login (Fallback for Bash users)
if command -v distrobox > /dev/null 2>&1; then
    if [ -t 1 ] && [ -z "$DISTROBOX_ENTERED" ]; then
        distrobox enter arch-dev
    fi
fi

# --- Zoxide ---
if command -v zoxide > /dev/null 2>&1; then
    eval "$(zoxide init bash)"
fi