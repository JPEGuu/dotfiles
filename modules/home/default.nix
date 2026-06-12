# Home Manager エントリポイント
# Phase ごとにモジュールを imports へ追加していく。
{ ... }:

{
  imports = [
    ./packages.nix             # home.packages（旧 pkglist.txt 相当）
    # Phase 5: ./shell.nix       — zsh / 環境変数 / エイリアス
    # Phase 5: ./programs.nix    — starship / zoxide / fzf / tmux / git ...
    # Phase 5: ./files.nix       — xdg.configFile（nvim / yazi / sheldon ...）
  ];

  home.username = "jpeguu";
  home.homeDirectory = "/home/jpeguu";

  # Home Manager の stateVersion（system.stateVersion と同様、初回固定値）。
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;
}
