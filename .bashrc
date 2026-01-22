# .bashrc

# --- AlmaLinux / RHEL / Global Settings ---
# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

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

# User specific aliases
alias dotpush='(cd ~/dotfiles && git push)'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias diff='diff --color=auto'

# Enter Arch when login (Fallback for Bash users)
if command -v distrobox > /dev/null 2>&1; then
    if [ -t 1 ] && [ -z "$DISTROBOX_ENTERED" ]; then
        distrobox enter arch-dev
    fi
fi