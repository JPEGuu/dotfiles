# WSL 固有のシステム設定
# 利用前提: flake の modules に nixos-wsl.nixosModules.default を含めること（flake.nix で設定済み）。
{ userConfig, ... }:

{
  wsl = {
    enable = true;
    # Windows 側から `wsl -d NixOS` で入った際のデフォルトユーザー
    defaultUser = userConfig.username;
    # Windows の PATH を引き継ぐ（code.exe 等を呼べるようにする）
    interop.includePath = true;
    # Windows 側ドライブの自動マウント先（既定 /mnt）
    wslConf.automount.root = "/mnt";
  };

  # WSL では systemd-networkd 等は不要（NixOS-WSL 側が面倒を見る）。
  # bootloader / hardware-configuration も WSL では不要なため定義しない。

  networking.hostName = "nixos-wsl";
}
