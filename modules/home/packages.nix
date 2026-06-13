# home.packages — 旧 pkglist.txt のユーザー向け CLI ツールを移行
#
# 方針:
# - 設定を伴うもの（starship/zoxide/fzf/tmux/git/neovim/yazi/sheldon）は
#   programs.nix 側で programs.* として有効化するため、ここには含めない。
# - NixOS オプションで扱うもの（docker/openssh/zsh/sudo/locale/GPU 等）は
#   common.nix / hosts/* 側で扱うため、ここには含めない。
# - 言語ランタイムとパッケージ未収録の AI CLI は Phase 6 で別途検討。
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # --- アーカイブ ---
    p7zip          # 7zip
    unzip
    zip
    pigz

    # --- 検索・閲覧・ファイル ---
    ripgrep        # rg
    fd
    tree
    less
    poppler-utils  # pdftotext / pdftoppm 等（Yazi の PDF プレビュー用。旧 pkglist: poppler）

    # --- システム監視・情報 ---
    bottom         # btm
    fastfetch
    lsof

    # --- ネットワーク ---
    mtr
    tcpdump
    traceroute
    inetutils      # telnet/ftp 等
    rsync

    # --- 画像・メディア ---
    imagemagick
    chafa
    ffmpegthumbnailer
    resvg

    # --- 開発: 言語ランタイム ---
    go
    rustup         # NixOS では rust-overlay/fenix も選択肢だが現状踏襲
    deno
    clojure
    jdk            # jdk-openjdk
    php
    php.packages.composer  # composer（旧 composer-global は廃止）

    # --- 設定ファイル主体のツール（設定は files.nix で参照）---
    neovim
    tmux
    yazi

    # --- 開発: ユーティリティ ---
    gh             # github-cli
    jq
    tree-sitter    # tree-sitter-cli
    rlwrap
    bc
    diffutils
    vim            # フォールバック用（メインは neovim/programs.nix）

    # --- man ---
    man-pages

    # メモ: 以下は NixOS 側で対応するため packages から除外
    #   docker / docker-compose -> virtualisation.docker (common.nix)
    #   openssh                 -> services.openssh       (common.nix)
    #   zsh / sudo / locale     -> common.nix
    #   mesa / vulkan-intel|radeon -> hardware.graphics   (hosts/desktop)
    #   nss-mdns                -> services.avahi (必要時に hosts/desktop で)
    #   xorg-xauth              -> SSH X11 forwarding 時に services.openssh で
    #   composer                -> Phase 6 (php.packages.composer)
  ];
}
