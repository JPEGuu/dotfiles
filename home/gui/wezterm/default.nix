# WezTerm（GUI ターミナル）。GUI 有効時のみパッケージ導入 + 設定リンク。
{ lib, osConfig, ... }:

{
  config = lib.mkIf (osConfig.my.gui.enable or false) {
    programs.wezterm = {
      enable = true;
      # enableZshIntegration の default は home.shell.enableZshIntegration 依存で
      # 未設定だと source 行が注入されないため明示 true。
      enableZshIntegration = true;
    };

    # settings/extraConfig を使わないため HM は wezterm.lua を生成せず、この symlink と衝突しない。
    xdg.configFile."wezterm/wezterm.lua".source = ./wezterm.lua;
  };
}
