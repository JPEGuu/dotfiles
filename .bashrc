# .bashrc

# --- AlmaLinux / RHEL / Global Settings ---
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# --- Shared Environment Variables ---
if [ -f "$HOME/.config/shell/env.sh" ]; then
    source "$HOME/.config/shell/env.sh"
fi

# --- Path settings ---
export PATH="$HOME/.local/bin:$HOME/.config/composer/vendor/bin:$PATH"

# --- Zsh Auto-Start ---
# If Zsh is available, launch it immediately.
if [ -t 1 ] && command -v zsh >/dev/null 2>&1; then
    exec zsh
fi

# =================================================================
# Fallback Settings (Used only if Zsh is NOT installed)
# =================================================================

# --- Modular Configs ---
if [ -f "$HOME/.config/shell/aliases.sh" ]; then
    source "$HOME/.config/shell/aliases.sh"
fi

# --- Distrobox Auto-Enter ---
if [ -f "$HOME/.config/shell/distrobox.sh" ]; then
    source "$HOME/.config/shell/distrobox.sh"
fi

# --- Zoxide ---
if command -v zoxide > /dev/null 2>&1; then
    eval "$(zoxide init bash)"
fi


# Added by Antigravity CLI installer
export PATH="/home/jpeguu/.local/bin:$PATH"
