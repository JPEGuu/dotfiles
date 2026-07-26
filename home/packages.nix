# home.packages — 旧 pkglist.txt のユーザー向け CLI ツールを移行
#
# 方針:
# - shell 統合だけで済むもの（starship/zoxide/fzf/git）は programs.nix 側で
#   programs.* として有効化する（パッケージも自動導入されるため、ここには含めない）。
# - 設定ファイル主体のもの（neovim/tmux/yazi）はここでパッケージを導入し、
#   設定は home/<tool>/ の各 module で参照する。
# - NixOS オプションで扱うもの（docker/openssh/zsh/sudo/locale/GPU 等）は
#   common.nix / hosts/* 側で扱うため、ここには含めない。
# - AI CLI は home/ai.nix で管理する。
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

    # --- 設定ファイル主体のツール（設定は各ツール module で参照）---
    neovim
    tmux
    yazi

    # --- 開発: ユーティリティ ---
    gcc            # Cコンパイラ (Neovim Treesitter parserのビルド等に必須)
    gnumake        # Make (ビルドツール)
    gh             # github-cli
    jq
    tree-sitter    # tree-sitter-cli
    rlwrap
    bc
    diffutils
    vim            # フォールバック用（メインは neovim）

    # --- man ---
    man-pages

    # メモ: 以下は NixOS 側で対応するため packages から除外
    #   docker / docker-compose -> virtualisation.docker (common.nix)
    #   openssh                 -> services.openssh       (common.nix)
    #   zsh / sudo / locale     -> common.nix
    #   mesa / vulkan-intel|radeon -> hardware.graphics   (hosts/desktop)
    #   nss-mdns                -> services.avahi (必要時に hosts/desktop で)
    #   xorg-xauth              -> SSH X11 forwarding 時に services.openssh で
  ];
}
