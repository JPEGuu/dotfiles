# Home Manager エントリポイント
# 機能・ツールごとに module を imports する。
{ userConfig, ... }:

{
  imports = [
    ./packages.nix    # home.packages（CLI ツール群）
    ./shell.nix       # zsh / 環境変数 / エイリアス / SKK辞書
    ./programs.nix    # starship / zoxide / fzf / git の enable
    ./ai              # claude-code / codex + Claude 設定（mkOutOfStoreSymlink）

    # 設定ファイル主体のツール（raw config を co-location）
    ./nvim
    ./tmux
    ./yazi
    ./starship
    ./clojure

    # GUI（osConfig.my.gui.enable で分岐。中身は各 module が mkIf ガード）
    ./gui
  ];

  home.username = userConfig.username;
  home.homeDirectory = userConfig.homeDirectory;

  home.stateVersion = "25.05";

  programs.home-manager.enable = true;
}
