# GUI（niri / Wayland）環境のユーザーレベル設定（Home Manager）。
#
# システム側の my.gui.enable に追従する（osConfig 経由）。
# WSL（my.gui.enable=false）では config ブロックが空になり何も導入しない。
{ lib, pkgs, osConfig, ... }:

{
  imports = [
    ./wezterm
    ./niri
    ./noctalia
  ];

  config = lib.mkIf (osConfig.my.gui.enable or false) {
    # --- niri + Noctalia Shell で使うユーザー向け GUI ツール群 ---
    # （システム権限が要るもの＝polkit エージェント / PAM / 音声サーバは nixos/gui.nix 側）
    home.packages = with pkgs; [
      # Noctalia lock の実機確認が終わるまでの退避用。確認後に削除予定。
      swaylock-effects # スクリーンロック（バイナリ名は swaylock）
      grim # スクリーンショット撮影
      slurp # 領域選択（grim と併用）
      swappy # 撮影後の注釈エディタ（任意）
      wl-clipboard # wl-copy / wl-paste
      brightnessctl # 輝度操作（キーバインドから）
      playerctl # メディアキー操作
      pavucontrol # GUI 音量コントロール
      firefox # ブラウザ
    ];
  };
}
