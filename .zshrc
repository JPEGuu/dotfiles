# .zshrc

# --- Global Definitions ---
if [ -f /etc/zshrc ]; then
    . /etc/zshrc
fi

# --- Shared Environment Variables ---
if [ -f "$HOME/.config/shell/env.sh" ]; then
    source "$HOME/.config/shell/env.sh"
fi

# --- Secrets / Local Configs (.env) ---
if [ -f "$HOME/.env" ]; then
    set -a
    source "$HOME/.env"
    set +a
fi

# --- NVM (Node Version Manager) ---
export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Prepend user bin directories to PATH if they exist
for dir in "$HOME/.local/bin" "$HOME/bin" "$HOME/.config/composer/vendor/bin" "$HOME/.cargo/bin"; do
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
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu select

# Prompt (Starship)
if command -v starship > /dev/null 2>&1; then
    eval "$(starship init zsh)"
else
    # Fallback Prompt
    autoload -Uz vcs_info
    precmd() { vcs_info }
    zstyle ':vcs_info:git:*' formats '(%b)'
    setopt PROMPT_SUBST
    PROMPT='%F{cyan}%n%f@%F{green}%m%f:%F{blue}%~%f ${vcs_info_msg_0_} %# '
fi

# --- Modular Configs ---
if [ -f "$HOME/.config/shell/aliases.sh" ]; then
    source "$HOME/.config/shell/aliases.sh"
fi

if [ -f "$HOME/.config/zsh/functions.zsh" ]; then
    source "$HOME/.config/zsh/functions.zsh"
fi

# --- Sheldon (Plugin Manager) ---
if command -v sheldon > /dev/null 2>&1; then
    eval "$(sheldon source)"
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

