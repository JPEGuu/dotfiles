# starship プロンプト設定。
# programs.starship.enable=true は programs.nix 側。settings を使わず raw toml を参照する
# （二重管理回避）。
{ ... }:

{
  xdg.configFile."starship.toml".source = ./starship.toml;
}
