# Neovim 設定（vim.pack ベース。lockfile を設定ディレクトリへ書くため out-of-store リンクにする）。
#
# 実行中に init.lua と nvim-pack-lock.json の変更が即時反映される。
{ config, ... }:

{
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/home/nvim/nvim";
}
