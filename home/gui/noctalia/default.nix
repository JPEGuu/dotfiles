# Noctalia Shell（バー/ランチャー/通知/ロック/壁紙の統合シェル）。GUI 有効時のみ。
#
# imports は条件化できないため無条件で読み込み、enable を mkIf でガードする
# （WSL では enable=false となり何も導入されない）。
{ lib, osConfig, noctalia, ... }:

{
  imports = [ noctalia.homeModules.default ];

  config = lib.mkIf (osConfig.my.gui.enable or false) {
    # 初回導入は enable のみ。settings を宣言すると settings.json が read-only symlink
    # になるため、GUI で調整した値を後から Nix に書き戻す。
    programs.noctalia-shell.enable = true;
  };
}
