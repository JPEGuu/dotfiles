# .zshrc

# --- Global Definitions ---
if [ -f /etc/zshrc ]; then
    . /etc/zshrc
fi

# --- Variables ---
export DOTFILES="$HOME/dotfiles"

# --- Environment Variables ---
export EDITOR=nvim
export VISUAL=nvim

# Prepend user bin directories to PATH if they exist
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

# --- Modular Configs ---
# Aliases
if [ -f "$HOME/.config/shell/aliases.sh" ]; then
    source "$HOME/.config/shell/aliases.sh"
fi

# Functions (Gemini, Pacman wrappers)
if [ -f "$HOME/.config/zsh/functions.zsh" ]; then
    source "$HOME/.config/zsh/functions.zsh"
fi

# --- Distrobox Auto-Enter (Host Side) ---
if command -v distrobox > /dev/null 2>&1; then
    if [ -t 1 ] && [ -z "$DISTROBOX_ENTERED" ]; then
        distrobox enter arch-dev
    fi
fi

# --- Sheldon (Plugin Manager) ---
if command -v sheldon > /dev/null 2>&1; then
    eval "$(sheldon source)"
fi

# --- Auto-start Zellij ---
if command -v zellij > /dev/null 2>&1; then
    # Only auto-start if in SSH, interactive, and not already in Zellij
    if [[ -n "$SSH_CONNECTION" ]] && [[ -z "$ZELLIJ" ]]; then
        zellij attach -c default
    fi
fi

# --- Extra Configs ---
if [ -d ~/.zshrc.d ]; then
    for rc in ~/.zshrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi

# --- Zoxide ---
if command -v zoxide > /dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi