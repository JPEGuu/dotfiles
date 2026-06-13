# dotfiles

CLI 完結型の開発環境を管理する dotfiles。Neovim / Tmux を中心とした、ターミナル上で開発を完結させるワークフローを構築する。

**NixOS（Nix Flakes + Home Manager）構成。** WSL 上の NixOS と実機（bare-metal）NixOS の両方を単一リポジトリでサポートする。

> 旧 Arch Linux 構成（`install.sh` + symlink、`pkglist.txt` などのパッケージリスト一式）は
> `archive/arch` ブランチに保存している。参照する場合はそちらを参照すること。

---

## ディレクトリ構成

```
dotfiles/
├── flake.nix                       # エントリポイント（nixosConfigurations.wsl / .desktop）
├── flake.lock                      # 入力リビジョン固定
├── hosts/
│   ├── wsl/configuration.nix       # WSL 固有（wsl.enable, defaultUser）
│   └── desktop/
│       ├── configuration.nix       # bare-metal 固有（systemd-boot, networkmanager, GPU）
│       └── hardware-configuration.nix  # ⚠️ 実機で生成して置き換える
├── modules/
│   ├── common.nix                  # 両環境共通（nix flakes, allowUnfree, user, zsh, docker, ssh, locale）
│   └── home/                       # Home Manager
│       ├── default.nix             # HM エントリ（imports 集約）
│       ├── packages.nix            # home.packages（ユーザー向け CLI ツール）
│       ├── shell.nix               # zsh / 環境変数 / エイリアス
│       ├── programs.nix            # starship / zoxide / fzf / git
│       ├── files.nix               # xdg.configFile（nvim / yazi / tmux / starship ...）
│       └── ai.nix                  # claude-code / codex + Claude 設定
└── .config/, claude/, templates/   # 既存設定（HM から source 参照）
```

## セットアップ

### WSL（NixOS-WSL）

```bash
# 1. リポジトリを clone
git clone https://github.com/JPEGuu/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 2. ビルド & 切り替え
sudo nixos-rebuild switch --flake .#wsl
```

### bare-metal（実機）

```bash
# 1. リポジトリを clone
git clone https://github.com/JPEGuu/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 2. hardware-configuration.nix を実機の出力で置き換える
sudo nixos-generate-config --show-hardware-config > hosts/desktop/hardware-configuration.nix

# 3. ビルド & 切り替え
sudo nixos-rebuild switch --flake .#desktop
```

## AI CLI

`claude-code` / `codex` は nixpkgs 収録パッケージを使用する（npm グローバル運用は廃止）。

`claude/` 配下に Claude Code のグローバル設定（`CLAUDE.md`, `settings.json`, `commands/`, `agents/`）を管理し、
`$HOME/.claude/` へリンクする。`settings.json` はアプリ自身が書き込むため、dotfiles リポジトリへの可変
symlink（`mkOutOfStoreSymlink`）にしている。

## メモ

- 実機（bare-metal）固有の `hardware-configuration.nix` はマシンごとに異なるため、
  ダミーをコミットしている。初回構築時に `nixos-generate-config` の出力で置き換えること。
