# ⚠️ プレースホルダ — 実機での生成が必須
#
# このファイルは実機ごとに固有の内容（ディスク UUID・ファイルシステム・カーネル
# モジュール等）を持つため、リポジトリのものをそのまま使ってはいけない。
#
# 実機に NixOS をインストールする際、以下で自動生成して置き換えること:
#
#     sudo nixos-generate-config --root /mnt
#     # 生成された /mnt/etc/nixos/hardware-configuration.nix を
#     # この hosts/desktop/hardware-configuration.nix にコピーする
#
# 下記はビルドを通すための最小ダミー定義。実機生成物で必ず上書きすること。
{ lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # 以下はダミー値。nixos-generate-config の出力で置き換える。
  boot.initrd.availableKernelModules = [ ];
  boot.kernelModules = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
