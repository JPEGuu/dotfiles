# 既存の設定ファイル群を Home Manager 管理下に置く。
#
# 方針: 設定が複雑なものは書き換えず、既存ファイルを source 参照する
# （旧 install.sh の symlink 運用を踏襲しつつ宣言的に）。
# 参照先は flake のソースツリー内（dotfiles/.config/*）で、ビルド時に
# nix store へコピーされ read-only でリンクされる。
#
# 注意: read-only リンクのため、ツールが設定ディレクトリへ書き込む場合は
# 別途 xdg.dataHome 等へ逃がすこと（nvim の mini.deps は data dir に書くため問題なし）。
{ ... }:

{
  xdg.configFile = {
    # Neovim（mini.deps ベース。プラグインは data dir に展開されるため設定は read-only で可）
    "nvim".source = ../../.config/nvim;

    # yazi（ファイルマネージャ）
    "yazi".source = ../../.config/yazi;

    # tmux
    "tmux/tmux.conf".source = ../../.config/tmux/tmux.conf;

    # starship（programs.starship.enable=true と併用。settings 未使用なので衝突しない）
    "starship.toml".source = ../../.config/starship.toml;

    # Clojure（deps.edn / tools）
    "clojure".source = ../../.config/clojure;

    # rtk（Rust Token Killer）設定
    "rtk".source = ../../.config/rtk;
  };
}
