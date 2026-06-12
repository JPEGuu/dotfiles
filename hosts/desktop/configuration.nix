# 実機（bare-metal）固有のシステム設定
{ ... }:

{
  # --- ブートローダー ---
  # UEFI 環境を想定（systemd-boot）。レガシー BIOS の場合は grub に変更すること。
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # --- ネットワーク ---
  networking.hostName = "nixos-desktop";
  networking.networkmanager.enable = true;

  # --- GPU / グラフィック ---
  # 実機の GPU に応じて有効化する。pkglist.txt にあった vulkan-intel/radeon に相当。
  # hardware.graphics.enable = true;
  # services.xserver.videoDrivers = [ "modesetting" ];  # Intel/AMD は modesetting で可

  # --- その他 ---
  # 実機固有の調整（音声 pipewire、Bluetooth、印刷 等）は必要に応じて追記する。
}
