# Home Manager エントリポイント
# Phase ごとにモジュールを imports へ追加していく。
{ ... }:

{
  imports = [
    ./packages.nix             # home.packages（旧 pkglist.txt 相当）
    ./shell.nix                # zsh / 環境変数 / エイリアス
    ./programs.nix             # starship / zoxide / fzf / git
    ./files.nix                # xdg.configFile（nvim / yazi / tmux / starship ...）
    ./ai.nix                   # claude-code / codex / rtk + Claude 設定
  ];

  home.username = "jpeguu";
  home.homeDirectory = "/home/jpeguu";

  # Home Manager の stateVersion（system.stateVersion と同様、初回固定値）。
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;
}
