{
  description = "jpeguu の dotfiles — WSL / bare-metal 両対応の NixOS + Home Manager 構成";

  inputs = {
    # nixpkgs は unstable を使用（最新ツールを取り込みやすくするため）
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home Manager（ユーザー環境を宣言的に管理）
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixOS-WSL（WSL 上で NixOS を動かすためのモジュール群）
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Noctalia Shell（niri 用デスクトップシェル。v4 安定系列）
    noctalia = {
      url = "github:noctalia-dev/noctalia/legacy-v4";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, nixos-wsl, noctalia, ... }:
    let
      system = "x86_64-linux";

      # 全ホスト共通で渡す引数
      specialArgs = { inherit nixos-wsl; };

      # Home Manager を NixOS モジュールとして組み込む共通設定
      homeManagerModule = {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = "hm-backup";
        home-manager.extraSpecialArgs = { inherit noctalia; };
        home-manager.users.jpeguu = import ./home;
      };
    in
    {
      nixosConfigurations = {
        # WSL 環境:  sudo nixos-rebuild switch --flake '.#wsl'
        wsl = nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules = [
            nixos-wsl.nixosModules.default
            ./hosts/wsl
            ./nixos/common.nix
            ./nixos/gui.nix # my.gui.enable オプションを定義（WSL では false のまま）
            home-manager.nixosModules.home-manager
            homeManagerModule
          ];
        };

        # 実機（bare-metal）環境:  sudo nixos-rebuild switch --flake '.#desktop'
        desktop = nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules = [
            ./hosts/desktop
            ./nixos/common.nix
            ./nixos/gui.nix # niri/ly/音声/フォント等の GUI 層（desktop で enable）
            home-manager.nixosModules.home-manager
            homeManagerModule
          ];
        };
      };
    };
}
