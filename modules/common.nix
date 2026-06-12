# 両環境（WSL / bare-metal）で共通のシステムレベル設定
{ pkgs, ... }:

{
  # --- Nix 本体の設定 ---
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };
  # 古い世代を自動 GC
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 30d";
  };

  # --- ロケール / タイムゾーン ---
  time.timeZone = "Asia/Tokyo";
  i18n.defaultLocale = "en_US.UTF-8";

  # --- ユーザー定義 ---
  users.users.jpeguu = {
    isNormalUser = true;
    description = "jpeguu";
    extraGroups = [ "wheel" "docker" ];
    shell = pkgs.zsh;
  };

  # zsh をシステムシェルとして有効化（users.users.*.shell に指定する前提）
  programs.zsh.enable = true;

  # --- システムレベルの最小パッケージ ---
  # ユーザー向けツールは Home Manager (modules/home/packages.nix) で管理する。
  # ここには「root でも使う / システム運用に必要」な最小限のみを置く。
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
  ];

  # --- Docker（compose 等を利用するため） ---
  virtualisation.docker.enable = true;

  # --- OpenSSH ---
  services.openssh.enable = true;

  # stateVersion は「初回インストール時の NixOS リリース」に固定する値。
  # 安易に上げないこと。実際にインストールした際のバージョンに合わせて確認・調整する。
  system.stateVersion = "25.05";
}
