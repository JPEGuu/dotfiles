# niri（Wayland コンポジタ）のユーザー設定。GUI 有効時のみリンク。
{ lib, osConfig, ... }:

{
  config = lib.mkIf (osConfig.my.gui.enable or false) {
    xdg.configFile."niri/config.kdl" = {
      source = ./config.kdl;
      # 初回 activation 前に niri が自動生成した config は、HM 側の内容で置き換える。
      force = true;
    };
  };
}
