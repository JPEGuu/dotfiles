# Neovim 設定（mini.deps ベース。プラグインは data dir に展開されるため read-only リンクで可）。
#
# 編集頻度が高く rebuild が煩わしくなった場合は、下記を mkOutOfStoreSymlink に
# 切り替えると即時反映になる（絶対パス必須・再現性は放棄）:
#   xdg.configFile."nvim".source =
#     config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/home/nvim/nvim";
{ ... }:

{
  xdg.configFile."nvim".source = ./nvim;
}
