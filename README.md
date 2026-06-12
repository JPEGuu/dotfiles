# dotfiles

CLI 完結型の開発環境を管理する dotfiles。Neovim / Tmux を中心とした、ターミナル上で開発を完結させるワークフローを構築する。

> [!IMPORTANT]
> **このリポジトリ内の設定ファイルは `install.sh` によって `$HOME` 配下へシンボリックリンクされている。**
> そのため `.zshrc` や `.config/` 配下のファイルをこのリポジトリ内で直接編集すると、**リンク経由で即座に稼働中の環境へ反映される**。検証目的で安全に試したい場合は、別ブランチで新規ファイルを追加する形で作業すること。

## 設計指針

- **冪等性 (Idempotency)**: `install.sh` は何度実行しても安全。既に正しい状態なら変更を加えない。パッケージは `--needed` でインストールし、既存ファイルはタイムスタンプ付きディレクトリへバックアップする。
- **CLI 完結型**: GUI ツールを含まず、ターミナル上での開発効率を最大化する。
- **Neovim / Tmux 中心**: ログイン時に Tmux セッションを自動開始し、その中で Neovim をターミナルとして起動する。

## リポジトリ構成

```
dotfiles/
├── install.sh              # セットアップスクリプト（symlink + パッケージ導入）
├── pkglist.txt             # Arch Linux パッケージリスト（pacman/yay）
├── cargo-packages.txt      # cargo install 対象（rtk 等）
├── npm-global.txt          # npm グローバルパッケージ
├── composer-global.txt     # composer グローバルパッケージ
├── .bashrc / .zshrc        # シェル設定（$HOME へ symlink）
├── .config/                # 各ツール設定（$HOME/.config/ へ個別 symlink）
│   ├── nvim/               #   Neovim (mini.nvim ベース)
│   ├── tmux/ yazi/ sheldon/ starship.toml
│   ├── shell/              #   env.sh, aliases.sh（共有環境変数・エイリアス）
│   ├── zsh/functions.zsh   #   Zsh ヘルパー関数群
│   └── rtk/                #   rtk (Rust Token Killer) 設定
├── claude/                 # Claude Code グローバル設定（$HOME/.claude/ へ symlink）
└── templates/              # プロジェクトテンプレート
```

## セットアップ

```bash
git clone <repo> ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` が行う処理:

1. **シンボリックリンク作成** — `.bashrc` / `.zshrc` を `$HOME` へ、`.config/` 配下の各エントリを `$HOME/.config/` へリンク。
2. **バックアップ** — 既存ファイルが symlink でなければ `~/.dotfiles_backup_YYYYMMDD_HHMMSS/` へ自動退避。
3. **パッケージ導入** — `pkglist.txt`（yay 経由で公式リポジトリ + AUR）、`cargo-packages.txt`、`npm-global.txt`、`composer-global.txt` をインストール。
4. **AI CLI 連携** — Claude Code のグローバル設定をリンクし、rtk フックを初期化。

## 主要ツール

| 分類 | ツール |
|------|--------|
| コア | `git`, `github-cli`, `ripgrep`, `fd`, `fzf`, `jq`, `yazi` |
| 開発環境 | `neovim`, `tmux`, `zsh`, `starship`, `zoxide`, `sheldon` |
| 言語ランタイム | `go`, `rustup`, `php`, `composer`, `deno`, `clojure`, `jdk-openjdk` |
| 監視・便利 | `bottom`, `chafa`, `fastfetch`, `7zip`, `rsync` |

## シェル環境の挙動

- **Bash → Zsh**: `.bashrc` は `zsh` が利用可能なら即 `exec zsh` するランチャー。Zsh 未導入時のフォールバックも担う。
- **プロンプト**: `starship`。未導入時は `vcs_info` ベースの簡易プロンプトへフォールバック。
- **プラグイン管理**: `sheldon`（zsh-syntax-highlighting / autosuggestions / completions）。
- **履歴**: 共有履歴（`SHARE_HISTORY`）＋重複無視（`HIST_IGNORE_DUPS`, `HIST_IGNORE_SPACE`）。
- **モジュール構成**: 環境変数は `.config/shell/env.sh`、エイリアスは `aliases.sh`、Zsh 関数は `.config/zsh/functions.zsh` に分離。

### Tmux & Neovim セッション

- シェル起動時、インタラクティブ端末かつ Neovim 外なら `main` セッションへアタッチ／新規作成（`tmux new-session -A -s main`）。
- Tmux 内では `nvim -c "terminal"` により Neovim をターミナルモードで起動し、IDE 兼ターミナルマルチプレクサとして利用する。

## メンテナンス

設定変更は `~/dotfiles` 内で行い、`install.sh` を再実行して反映する。パッケージ追加・削除は以下のヘルパー関数（`functions.zsh` 定義）を使うと、リストファイルの更新とコミットが自動化される。

| 関数 | 用途 |
|------|------|
| `pacin` / `pacrm` | pacman パッケージ導入・削除 → `pkglist.txt` 自動更新 |
| `cargo-in` / `cargo-rm` | cargo パッケージ → `cargo-packages.txt` 自動更新 |
| `npmg-in` / `npmg-rm` | npm グローバル → `npm-global.txt` 自動更新 |
| `composerg-in` / `composerg-rm` | composer グローバル → `composer-global.txt` 自動更新 |
| `dotfiles-adopt <name>` | 既存の `~/.config/<name>` を dotfiles 管理下へ移動して symlink 化 |

## AI アシスタント (Claude Code)

`claude/` 配下に Claude Code のグローバル設定（`CLAUDE.md`, `settings.json`, `commands/`, `agents/`）を管理し、`$HOME/.claude/` へリンクする。rtk によりコンテキスト消費（トークン）を最適化する。

## rtk (Rust Token Killer)

AI CLI のトークン消費を削減するツール（https://github.com/rtk-ai/rtk）。

- **導入**: `cargo-packages.txt` に `--git https://github.com/rtk-ai/rtk` を記載（crates.io に同名の別パッケージがあるため必ず GitHub を指定）。`install.sh` の cargo インストール処理は `--git` 等のオプション付き行を解釈できる。
- **設定**: `~/.config/rtk/config.toml` を `.config/rtk/` で管理。
- **フック**: `install.sh` 内で `rtk init -g --claude-md` を実行し、Claude Code に統合する。

---

## NixOS 移行計画（進行中）

現行の Arch Linux + `install.sh` ベースの構成を **NixOS（Nix Flakes + Home Manager）** へ移行中。WSL 上の NixOS と実機（bare-metal）NixOS の両方で動作する単一リポジトリ構成を目指す。

### 方針

- **両環境対応**: `flake.nix` の `nixosConfigurations` に `wsl` / `desktop` を定義し、`hosts/` で環境固有設定、`modules/common.nix` で共通設定を分離する。WSL 側は `nix-community/NixOS-WSL` モジュールを利用。
- **AI CLI 変更**: Gemini CLI を廃止し、**OpenAI Codex CLI** を導入する（nixpkgs 未収録のため当面は npm グローバル or `buildNpmPackage` で管理）。
- **Distrobox 廃止**: コンテナ自動エントリ機構は削除。
- **既存設定の再利用**: Neovim 等の複雑な設定は当面 `xdg.configFile."<name>".source` で既存ファイルをそのまま参照し、段階的に Home Manager モジュール化する。

### 想定構成

```
hosts/
  wsl/configuration.nix          # WSL 固有（wsl.enable, defaultUser）
  desktop/configuration.nix      # bare-metal 固有（bootloader, GPU）
  desktop/hardware-configuration.nix
modules/
  common.nix                     # 両環境共通のシステム設定
  home/                          # Home Manager モジュール群
pkgs/
  rtk.nix                        # rtk カスタム derivation
flake.nix
```

切り替えは `nixos-rebuild switch --flake '.#wsl'` / `'.#desktop'` で行う。
