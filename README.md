# dotfiles

---

## ディレクトリ構成

```
dotfiles/
├── flake.nix                           # エントリポイント（nixosConfigurations.wsl / .desktop）
├── flake.lock                          # 入力リビジョン固定
├── hosts/
│   ├── wsl/default.nix                 # WSL 固有（wsl.enable, defaultUser）
│   └── desktop/
│       ├── default.nix                 # bare-metal 固有（systemd-boot, networkmanager, my.gui.enable=true）
│       └── hardware-configuration.nix  # ⚠️ 実機で生成して置き換える
├── nixos/
│   ├── common.nix                      # 両環境共通（nix flakes, allowUnfree, user, zsh, docker, ssh, locale）
│   └── gui.nix                         # GUI システム層（my.gui.enable: niri / ly / PipeWire / フォント / polkit）
├── home/                               # Home Manager
│   ├── default.nix                     # HM エントリ（imports 集約）
│   ├── packages.nix                    # home.packages（ユーザー向け CLI ツール）
│   ├── shell.nix                       # zsh / 環境変数 / エイリアス / SKK辞書
│   ├── programs.nix                    # starship / zoxide / fzf / git の enable
│   ├── ai.nix                          # claude-code / codex + AI assistant 設定
│   ├── nvim/                           # Neovim 設定（raw config co-location）
│   ├── tmux/                           # tmux 設定
│   ├── yazi/                           # yazi 設定
│   ├── starship/                       # starship.toml
│   ├── clojure/                        # deps.edn / tools
│   └── gui/                            # GUI ユーザー層（wezterm / niri / Noctalia。osConfig.my.gui.enable で分岐）
└── claude/
    ├── CLAUDE.md                       # Claude Code / Codex 共通コンテキスト
    ├── commands/                       # Claude Code 用共有コマンド
    └── agents/                         # Claude Code 用共有 subagent 定義
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

## 設定の更新

初回セットアップ後は、リポジトリの設定を編集してからリビルド用エイリアスで反映する
（`nrs-*` は `home/shell.nix` 由来のため、初回 activation 後に利用可能）。

### WSL（NixOS-WSL）

```bash
# 1. 設定を編集
cd ~/dotfiles

# 2. ビルド & 切り替え
nrs-wsl
```

### bare-metal（実機）

```bash
# 1. 設定を編集
cd ~/dotfiles

# 2. ビルド & 切り替え
nrs-desktop
```

- `nrs-wsl` / `nrs-desktop` は `$DOTFILES`（既定 `~/dotfiles`）を参照するため、任意のディレクトリから実行できる。
- 変更を push する場合は `dotpush`（`$DOTFILES` で `git push` を実行）。

## メモ

- 実機（bare-metal）固有の `hardware-configuration.nix` はマシンごとに異なるため、
  ダミーをコミットしている。初回構築時に `nixos-generate-config` の出力で置き換えること。
