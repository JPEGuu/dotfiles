# dotfiles

開発環境を管理する dotfiles。Neovim / Tmux を中心とした **TUI 環境**と、niri / WezTerm を中心とした
**GUI 環境（Wayland）**の両方を、単一リポジトリで管理する。

**NixOS（Nix Flakes + Home Manager）構成。** WSL 上の NixOS（TUI のみ）と実機（bare-metal）NixOS
（TUI + GUI）の両方を単一リポジトリでサポートする。TUI/GUI の切り替えは `my.gui.enable` オプション一つで行う。

> 旧 Arch Linux 構成（`install.sh` + symlink、`pkglist.txt` などのパッケージリスト一式）は
> `archive/arch` ブランチに保存している。参照する場合はそちらを参照すること。

---

## ディレクトリ構成

```
dotfiles/
├── flake.nix                       # エントリポイント（nixosConfigurations.wsl / .desktop）
├── flake.lock                      # 入力リビジョン固定
├── hosts/
│   ├── wsl/default.nix             # WSL 固有（wsl.enable, defaultUser）
│   └── desktop/
│       ├── default.nix             # bare-metal 固有（systemd-boot, networkmanager, my.gui.enable=true）
│       └── hardware-configuration.nix  # ⚠️ 実機で生成して置き換える
├── nixos/
│   ├── common.nix                  # 両環境共通（nix flakes, allowUnfree, user, zsh, docker, ssh, locale）
│   └── gui.nix                     # GUI システム層（my.gui.enable: niri / ly / PipeWire / フォント / polkit）
├── home/                           # Home Manager
│   ├── default.nix                 # HM エントリ（imports 集約）
│   ├── packages.nix                # home.packages（ユーザー向け CLI ツール）
│   ├── shell.nix                   # zsh / 環境変数 / エイリアス / SKK辞書
│   ├── programs.nix                # starship / zoxide / fzf / git の enable
│   ├── ai.nix                      # claude-code / codex + AI assistant 設定
│   ├── nvim/                       # Neovim 設定（raw config co-location）
│   ├── tmux/                       # tmux 設定
│   ├── yazi/                       # yazi 設定
│   ├── starship/                   # starship.toml
│   ├── clojure/                    # deps.edn / tools
│   └── gui/                        # GUI ユーザー層（wezterm / niri / Noctalia。osConfig.my.gui.enable で分岐）
└── claude/
    ├── CLAUDE.md                   # Claude Code / Codex 共通コンテキスト
    ├── commands/                   # Claude Code 用共有コマンド
    └── agents/                     # Claude Code 用共有 subagent 定義
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

## TUI / GUI 環境

TUI と GUI は NixOS の独自オプション `my.gui.enable`（`nixos/gui.nix` で定義）一つで切り替える。

| | TUI（`my.gui.enable = false`） | GUI（`my.gui.enable = true`） |
|---|---|---|
| 対象ホスト | `wsl` | `desktop` |
| 構成 | Neovim / Tmux / Yazi / zsh | TUI 一式 ＋ niri / WezTerm |
| 追加されるもの | なし | コンポジタ・ログイン・音声・フォント・GUI アプリ |

- **システム層** `nixos/gui.nix` … `my.gui.enable` を定義し、true のホストでのみ
  niri（Wayland コンポジタ）/ ly（TUI ログインマネージャ）/ PipeWire（音声）/ フォント /
  polkit エージェント / `hardware.graphics` をまとめて構成する。
  flake では全ホストに読み込むが、WSL では `false` のままなので何も増えない。
- **ユーザー層** `home/gui` … `osConfig.my.gui.enable` に追従し、WezTerm / niri /
  Noctalia Shell と、補助ツール（swaylock / grim+slurp / wl-clipboard / brightnessctl /
  playerctl / pavucontrol / firefox）を導入する。
- **設定ファイル** … raw config は `home/<tool>/` 配下に co-location し、
  `xdg.configFile` で symlink する。GUI 設定は `home/gui/wezterm/wezterm.lua` と
  `home/gui/niri/config.kdl` を GUI 有効時のみリンクする。

GUI 環境のキーバインドは Mod=Super。端末は `Mod+Return`（WezTerm）、ランチャは `Mod+D`（Noctalia）。
WezTerm はタブ/ペインを自前で持つため、GUI では tmux を使わない（cheat sheet は `wezterm.lua` 冒頭）。

> 補足: 壁紙は Noctalia の wallpaper 機能で設定する。スクリーンショット保存先
> （`~/Pictures/Screenshots/`）は各自で用意すること（無くても致命的ではない）。

## AI CLI

`claude-code` / `codex` は nixpkgs 収録パッケージを使用する（npm グローバル運用は廃止）。

`claude/CLAUDE.md` を Claude Code / Codex 共通のコンテキストとして Git 管理し、
`$HOME/.claude/CLAUDE.md` と `$HOME/.codex/AGENTS.md` の両方へリンクする。
Codex に各プロジェクトの `CLAUDE.md` も instruction file として扱わせる場合は、
ユーザー側の `$HOME/.codex/config.toml` に `project_doc_fallback_filenames = ["CLAUDE.md"]` を設定する。

Claude Code 固有の共有資産である `commands/`, `agents/` は `claude/` 配下で管理し、
`$HOME/.claude/` へリンクする。`$HOME/.claude/settings.json`, `$HOME/.claude/policy-limits.json`,
`$HOME/.claude.json`, `$HOME/.codex/config.toml` などの live config と実行時 state は Git / Nix 管理せず、
Git 管理下にはタスクやプロジェクトに依存しない汎用ルールだけを置く。

## メモ

- 実機（bare-metal）固有の `hardware-configuration.nix` はマシンごとに異なるため、
  ダミーをコミットしている。初回構築時に `nixos-generate-config` の出力で置き換えること。
