# zsh / 環境変数 / エイリアス
# 旧 .zshrc + .config/shell/{env.sh,aliases.sh} を Home Manager へ移植。
#
# 移行メモ:
# - zsh プラグインは sheldon を廃止し HM ネイティブへ
#   (autosuggestion / syntaxHighlighting / zsh-completions)。
# - NVM は廃止（Node は home/ai.nix の nodejs_22 で Nix 管理）。
# - pacin/cargo-in/composerg/npmg/dotfiles-adopt 等の関数は
#   Arch/symlink 運用前提のため移植しない（NixOS では nixos-rebuild 運用）。
{ config, pkgs, lib, osConfig, ... }:

{
  # zsh 設定は XDG 配置へ移さず、従来どおりホーム直下の ~/.zshrc を HM 管理にする。
  # 初回 activation 前に zsh が生成した ~/.zshrc は、HM 側の内容で置き換える。
  home.file."./.zshrc".force = true;

  # SKK 辞書（skkeleton が ~/.skk/SKK-JISYO.L を参照するため配置）
  home.file.".skk/SKK-JISYO.L".source =
    "${pkgs.skkDictionaries.l}/share/skk/SKK-JISYO.L";

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
    dotDir = config.home.homeDirectory;
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
      # cat の代替（-p=plain: 行番号等の装飾なし, -p=paging never）
      cat = "bat -pp";
      grep = "grep --color=auto";
      diff = "diff --color=auto";
      # ll / la / l は eza へ置き換え（ls 本体は coreutils のまま）
      ll = "eza -la --icons --git --group-directories-first";
      la = "eza -a --icons --group-directories-first";
      l = "eza --icons --group-directories-first";
      # NixOS 運用ショートカット
      nrs-wsl = "sudo nixos-rebuild switch --flake \"$DOTFILES#wsl\"";
      nrs-desktop = "sudo nixos-rebuild switch --flake \"$DOTFILES#desktop\"";
    };

    initContent = ''
      ${lib.optionalString (!(osConfig.my.gui.enable or false)) ''
        # --- tmux auto-start (WSL / CLI-only 環境のみ。GUI では起動しない) ---
        # 対話シェル & tmux 未起動のときだけ、既存セッションへアタッチ（無ければ新規）。
        # 非対話（Claude Code の Bash / nixos-rebuild / ssh cmd 等）や tmux ネストでは起動しない。
        # VS Code 統合ターミナルで無効化したい場合は [[ "$TERM_PROGRAM" != vscode ]] を条件に追加。
        if [[ $- == *i* ]] && [[ -z "$TMUX" ]] && command -v tmux >/dev/null; then
            tmux attach 2>/dev/null || tmux new-session
        fi
      ''}
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
