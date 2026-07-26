# 実機（bare-metal）固有のシステム設定
{ ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # --- ブートローダー ---
  # UEFI 実機用 systemd-boot。ESP は /boot マウント前提（hardware-configuration.nix で定義）。
  # GRUB は systemd-boot 有効化により自動で無効になる。
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # --- ネットワーク ---
  networking.hostName = "nixos-desktop";
  networking.networkmanager.enable = true;

  # --- GUI（niri / Wayland）環境を有効化 ---
  # niri / ly / PipeWire / フォント / polkit / hardware.graphics 等は
  # nixos/gui.nix が my.gui.enable=true のときにまとめて構成する。
  my.gui.enable = true;

  # --- GPU / グラフィック（補足） ---
  # hardware.graphics.enable は nixos/gui.nix で有効化済み。
  # 特定 GPU 向けドライバ（NVIDIA 等）が必要な場合のみここで追記する:
  #   services.xserver.videoDrivers = [ "nvidia" ];  # Intel/AMD は modesetting で自動

  # --- その他 ---
  # Bluetooth・印刷 等の実機固有サービスは必要に応じてここに追記する。
}
