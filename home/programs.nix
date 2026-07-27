# shell 統合が必要なツールを Home Manager の programs.* で有効化。
#
# 方針:
# - starship / zoxide / fzf は shell init を HM に任せる（パッケージも自動導入）。
#   設定ファイルを持つ starship は settings を使わず、home/starship で
#   raw toml を参照する（二重管理回避）。
# - tmux / yazi / neovim は設定ファイル主体のため programs.* を使わず、
#   packages.nix でツールを導入し各ツール module で既存設定を参照する。
{ userConfig, ... }:

{
  programs.starship.enable = true;
  programs.zoxide.enable = true;
  programs.fzf.enable = true;

  # cat の代替。設定は持たず既定のまま導入する。
  programs.bat.enable = true;

  # ls の代替。ただし ls 自体は従来の coreutils を維持したいので
  # 自動エイリアス（ls/ll/la/lt を eza へ置換）は無効化し、
  # ll / la のみ shell.nix の shellAliases で手動設定する。
  programs.eza = {
    enable = true;
    enableZshIntegration = false;
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    # コミット著者情報。メール実アドレスを晒さないため GitHub の noreply を使う。
    # 形式: <numeric-id>+<login>@users.noreply.github.com（gh api user で確認）。
    settings.user.name = userConfig.git.name;
    settings.user.email = userConfig.git.email;
  };
}
