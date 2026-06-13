# dotfiles

CLI 完結型の開発環境を管理する dotfiles。Neovim / Tmux を中心とした、ターミナル上で開発を完結させるワークフローを構築する。

**Arch Linux ベース（`install.sh` + symlink）から NixOS（Nix Flakes + Home Manager）へ移行中。** NixOS 構成は WSL 上の NixOS と実機（bare-metal）NixOS の両方を単一リポジトリでサポートする。実機での検証後、このリポジトリ自体も NixOS 構成へ全面移行し、レガシー資産は削除する予定。

---

## NixOS 構成（移行先）

### ディレクトリ構成

```
dotfiles/
├── flake.nix                       # エントリポイント（nixosConfigurations.wsl / .desktop）
├── flake.lock                      # 入力リビジョン固定（検証済み）
├── hosts/
│   ├── wsl/configuration.nix       # WSL 固有（wsl.enable, defaultUser）
│   └── desktop/
│       ├── configuration.nix       # bare-metal 固有（systemd-boot, networkmanager, GPU）
│       └── hardware-configuration.nix  # ⚠️ 実機で生成して置き換える
├── modules/
│   ├── common.nix                  # 両環境共通（nix flakes, allowUnfree, user, zsh, docker, ssh, locale）
│   └── home/                       # Home Manager
│       ├── default.nix             # HM エントリ（imports 集約）
│       ├── packages.nix            # home.packages（旧 pkglist.txt 相当）
│       ├── shell.nix               # zsh / 環境変数 / エイリアス
│       ├── programs.nix            # starship / zoxide / fzf / git
│       ├── files.nix               # xdg.configFile（nvim / yazi / tmux / starship ...）
│       └── ai.nix                  # claude-code / codex / rtk + Claude 設定
├── pkgs/
│   └── rtk.nix                     # rtk カスタム derivation（buildRustPackage）
└── .config/, claude/, templates/   # 既存設定（HM から source 参照）
```

### セットアップ

#### WSL（NixOS-WSL）

```bash
# Windows 側で NixOS-WSL の tarball を import 後、NixOS 内で:
git clone <repo> ~/dotfiles
sudo nixos-rebuild switch --flake '~/dotfiles#wsl'
```

#### 実機（bare-metal）

```bash
# インストーラで起動しディスク準備後:
sudo nixos-generate-config --root /mnt
# 生成された hardware-configuration.nix を置き換える
cp /mnt/etc/nixos/hardware-configuration.nix ~/dotfiles/hosts/desktop/hardware-configuration.nix

sudo nixos-rebuild switch --flake '~/dotfiles#desktop'
```

以後の再ビルドは zsh エイリアス `nrs-wsl` / `nrs-desktop` でも可能。

### ⚠️ 初回ビルド前に必要な手当て

| 項目 | ファイル | 対応 |
|------|---------|------|
| 実機ハードウェア定義 | `hosts/desktop/hardware-configuration.nix` | `nixos-generate-config` の出力で置き換え（現状プレースホルダ）|
| rtk のハッシュ | `pkgs/rtk.nix` | `src.hash` / `cargoHash` の `lib.fakeHash` を初回ビルドのエラーが示す実ハッシュに置換 |
| stateVersion | `modules/common.nix`, `modules/home/default.nix` | 実際にインストールした NixOS リリースに合わせる |
| Claude 設定の可変リンク | `modules/home/ai.nix` | dotfiles リポジトリが `~/dotfiles` にある前提（`settings.json` を可変 symlink）|

### コンテナでの検証状況

`nixos/nix` イメージ上で flake 評価とパッケージ実動作を検証済み（`nixos-rebuild` のフルシステム構築はコンテナでは不可）。

- ✅ `nixosConfigurations.wsl` / `.desktop` の `toplevel.drvPath` 算出に成功（全モジュール評価がビルド直前まで成立）
- ✅ `packages.nix` の全パッケージ attribute 存在を確認（`poppler-utils` 等）
- ✅ AI CLI 実起動: **claude-code 2.1.170** / **codex 0.137.0**
- ✅ `php.packages.composer`（composer-2.10.1）の attribute path が正しいことを確認
- ⚠️ `claude-code` は **unfree** ライセンス → `nixpkgs.config.allowUnfree = true`（common.nix で対応済み）。`codex` は free。
- ⏳ 実ビルドは未実施（rtk が `fakeHash`、hardware-config がダミーのため）

### 設計上のポイント

- **WSL / bare-metal の分離**: 共通部分は `modules/common.nix`、環境固有は `hosts/*` に分け、`flake.nix` の `nixosConfigurations` で組み合わせる。
- **zsh プラグイン**: sheldon を廃止し Home Manager ネイティブ（syntaxHighlighting / autosuggestion / zsh-completions）で管理。
- **AI CLI**: `claude-code` / `codex` は nixpkgs 収録パッケージを使用（npm グローバル運用は廃止）。`rtk` のみ未収録のため `pkgs/rtk.nix` で自前ビルド。
- **既存設定の踏襲**: Neovim 等の複雑な設定は書き換えず、`xdg.configFile.<name>.source` で既存ファイルを参照する。
- **Node**: 旧 NVM を廃止し `nodejs_22`（Nix 管理）に置き換え。

### 主要ツール

| 分類 | ツール |
|------|--------|
| コア | `git`, `gh`, `ripgrep`, `fd`, `fzf`, `jq`, `yazi` |
| 開発環境 | `neovim`, `tmux`, `zsh`, `starship`, `zoxide` |
| 言語ランタイム | `go`, `rustup`, `php`(+composer), `deno`, `clojure`, `jdk`, `nodejs` |
| 監視・便利 | `bottom`, `chafa`, `fastfetch`, `p7zip`, `rsync`, `poppler-utils` |
| AI CLI | `claude-code`, `codex`, `rtk` |

---

## シェル環境の挙動

- **Bash → Zsh**: `.bashrc` は `zsh` が利用可能なら即 `exec zsh` するランチャー。Zsh 未導入時のフォールバックも担う。
- **プロンプト**: `starship`。
- **履歴**: 共有履歴（`SHARE_HISTORY`）＋重複無視（`HIST_IGNORE_DUPS`, `HIST_IGNORE_SPACE`）。
- **モジュール構成（レガシー）**: 環境変数 `.config/shell/env.sh`、エイリアス `aliases.sh`、Zsh 関数 `.config/zsh/functions.zsh`。NixOS では `modules/home/shell.nix` に集約。

---

## AI アシスタント (Claude Code)

`claude/` 配下に Claude Code のグローバル設定（`CLAUDE.md`, `settings.json`, `commands/`, `agents/`）を管理し、`$HOME/.claude/` へリンクする。`settings.json` はアプリ自身が書き込むため、NixOS 構成では dotfiles リポジトリへの可変 symlink にしている。rtk によりコンテキスト消費（トークン）を最適化する。

### rtk (Rust Token Killer)

AI CLI のトークン消費を削減するツール（https://github.com/rtk-ai/rtk）。crates.io に同名の別パッケージがあるため必ず GitHub リポジトリを使う。NixOS では `pkgs/rtk.nix` でビルドし、`rtk init -g --claude-md` を Home Manager の activation で実行する。

---

## レガシー（Arch Linux）構成

NixOS 移行が完了するまで、Arch ベースの構成も残している（移行完了後に削除予定）。

```bash
git clone <repo> ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` が行う処理:

1. **シンボリックリンク作成** — `.bashrc` / `.zshrc` を `$HOME` へ、`.config/` 配下を `$HOME/.config/` へリンク。
2. **バックアップ** — 既存ファイルが symlink でなければ `~/.dotfiles_backup_YYYYMMDD_HHMMSS/` へ退避。
3. **パッケージ導入** — `pkglist.txt`（yay）、`cargo-packages.txt`、`npm-global.txt` をインストール。
4. **AI CLI 連携** — Claude Code 設定をリンクし rtk フックを初期化。

### メンテナンス用ヘルパー関数（レガシー）

`functions.zsh` 定義。パッケージ追加・削除時にリストファイル更新とコミットを自動化する。

| 関数 | 用途 |
|------|------|
| `pacin` / `pacrm` | pacman → `pkglist.txt` 更新 |
| `cargo-in` / `cargo-rm` | cargo → `cargo-packages.txt` 更新 |
| `npmg-in` / `npmg-rm` | npm グローバル → `npm-global.txt` 更新 |
| `composerg-in` / `composerg-rm` | composer → `composer-global.txt` 更新 |
| `dotfiles-adopt <name>` | `~/.config/<name>` を dotfiles 管理下へ移動して symlink 化 |

> NixOS へ完全移行後、これらのレガシー資産（`install.sh`, `pkglist.txt`, `cargo-packages.txt`, `npm-global.txt`, `composer-global.txt`, `.config/sheldon/`）は削除予定。
