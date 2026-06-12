# shell 統合が必要なツールを Home Manager の programs.* で有効化。
#
# 方針:
# - starship / zoxide / fzf は shell init を HM に任せる（パッケージも自動導入）。
#   設定ファイルを持つ starship は settings を使わず、既存 starship.toml を
#   files.nix の xdg.configFile で参照する（二重管理回避）。
# - tmux / yazi / neovim は設定ファイル主体のため programs.* を使わず、
#   packages.nix でツールを導入し files.nix で既存設定を参照する。
{ ... }:

{
  programs.starship.enable = true;
  programs.zoxide.enable = true;
  programs.fzf.enable = true;

  programs.git = {
    enable = true;
    # user.name / user.email は環境に応じて設定すること。
    # userName = "...";
    # userEmail = "...";
  };
}
