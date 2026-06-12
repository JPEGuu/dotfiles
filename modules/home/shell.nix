# zsh / 環境変数 / エイリアス
# 旧 .zshrc + .config/shell/{env.sh,aliases.sh} を Home Manager へ移植。
#
# 移行メモ:
# - zsh プラグインは sheldon を廃止し HM ネイティブへ
#   (autosuggestion / syntaxHighlighting / zsh-completions)。
# - NVM は廃止（Node は Nix 管理: Phase 6）。
# - pacin/cargo-in/composerg/npmg/dotfiles-adopt 等の関数は
#   Arch/symlink 運用前提のため移植しない（NixOS では nixos-rebuild 運用）。
{ config, pkgs, ... }:

{
  # --- 共有環境変数（旧 env.sh）---
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    DOTFILES = "${config.home.homeDirectory}/dotfiles";
  };

  # 旧 .zshrc の PATH 前置（存在すれば追加）
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/bin"
    "$HOME/.cargo/bin"
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # 旧 sheldon の zsh-completions 相当（追加補完定義）
    plugins = [
      {
        name = "zsh-completions";
        src = pkgs.zsh-completions;
      }
    ];

    history = {
      size = 10000;
      save = 20000;
      path = "${config.home.homeDirectory}/.zsh_history";
      append = true;
      share = true;
      ignoreDups = true;
      ignoreSpace = true;
    };

    # --- 共有エイリアス（旧 aliases.sh）---
    shellAliases = {
      dotpush = ''(cd "$DOTFILES" && git push)'';
      ls = "ls --color=auto";
      grep = "grep --color=auto";
      diff = "diff --color=auto";
      ll = "ls -alF";
      la = "ls -A";
      l = "ls -CF";
      # NixOS 運用ショートカット
      nrs-wsl = "sudo nixos-rebuild switch --flake \"$DOTFILES#wsl\"";
      nrs-desktop = "sudo nixos-rebuild switch --flake \"$DOTFILES#desktop\"";
    };

    initContent = ''
      # --- Secrets / Local Configs (.env) ---
      if [ -f "$HOME/.env" ]; then
          set -a
          source "$HOME/.env"
          set +a
      fi

      # 補完の挙動（旧 .zshrc）
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
      zstyle ':completion:*' menu select

      # --- Extra Configs (~/.zshrc.d) ---
      if [ -d ~/.zshrc.d ]; then
          for rc in ~/.zshrc.d/*; do
              [ -f "$rc" ] && . "$rc"
          done
      fi
    '';
  };
}
