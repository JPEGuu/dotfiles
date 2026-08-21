# 両環境（WSL / bare-metal）で共通のシステムレベル設定
{ pkgs, userConfig, ... }:

{
  # --- Nix 本体の設定 ---
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;

    # Noctalia Shell の binary cache。WSL から desktop をビルドする場合にも使えるよう共通層に置く。
    # nixpkgs.follows により cache miss する可能性はあるため、dry-run で確認する。
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  # unfree パッケージを許可。
  # 全許可ではなく特定のみ許可したい場合は allowUnfreePredicate を使う。
  nixpkgs.config.allowUnfree = true;

  # 古い世代を自動 GC
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 30d";
  };

  # --- ロケール / タイムゾーン ---
  time.timeZone = "Asia/Tokyo";
  i18n.defaultLocale = "en_US.UTF-8";

  # --- ユーザー定義 ---
  users.users.${userConfig.username} = {
    isNormalUser = true;
    description = userConfig.description;
    extraGroups = [ "wheel" "docker" ];
    shell = pkgs.zsh;
  };

  # zsh をシステムシェルとして有効化（users.users.*.shell に指定する前提）
  programs.zsh.enable = true;

  # --- システムレベルの最小パッケージ ---
  # ユーザー向けツールは Home Manager (home/packages.nix) で管理する。
  # ここには「root でも使う / システム運用に必要」な最小限のみを置く。
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
  ];

  # nix-ld: 汎用Linux向けダイナミックリンクバイナリを実行可能にする。
  # Mason (Neovim) がダウンロードする LSP バイナリ（lua-language-server / rust-analyzer 等）が
  # NixOS の FHS 非準拠環境でも動くように必要。
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib  # libstdc++ / libgcc_s（C++ バイナリに必須）
      zlib
      openssl
    ];
  };

  # --- Docker（compose 等を利用するため） ---
  virtualisation.docker.enable = true;

  # --- OpenSSH ---
  services.openssh.enable = true;

  # stateVersion は「初回インストール時の NixOS リリース」に固定する値。
  # 安易に上げないこと。実際にインストールした際のバージョンに合わせて確認・調整する。
  system.stateVersion = "25.05";
}
