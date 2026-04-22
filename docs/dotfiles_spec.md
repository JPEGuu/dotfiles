# Dotfiles 仕様書 (Status Report)

このドキュメントは、現在の `dotfiles` リポジトリの構成と期待される挙動をまとめたものです。

## 1. 設計指針
- **羃等性 (Idempotency) の担保**: `install.sh` は何度実行しても安全であり、既に正しい状態であれば変更を加えません。パッケージインストールには `pacman --needed` を使用し、既存のファイルはバックアップされます。
- **CLI 完結型の構成**: GUI ツールを一切含まず、ターミナル上での開発効率を最大化するように設計されています。
- **Neovim / Tmux 中心のワークフロー**: ログイン時に自動的に Tmux セッションを開始し、その中で Neovim を起動してターミナルとして利用する高度な設定が施されています。

## 2. インストール・セットアップ (`install.sh`)
`install.sh` を実行することで、以下の処理が自動的に行われます。
1. **シンボリックリンクの作成**:
   - `.bashrc`, `.zshrc` をホームディレクトリへ。
   - `.config/` 配下の全エントリ（ディレクトリ: `nvim`, `tmux`, `yazi`, `clojure`, `sheldon`, `shell`, `zsh`、ファイル: `starship.toml`）を `$HOME/.config/` へ個別にリンク。
2. **バックアップ機能**:
   - 既存のファイルがシンボリックリンクでない場合、タイムスタンプ付きのディレクトリ（例: `~/.dotfiles_backup_YYYYMMDD_HHMMSS/`）に自動退避します。
3. **パッケージの一括インストール**:
   - `pkglist.txt` に基づき、Arch Linux の `pacman` を用いて依存ツールをインストールします。

## 3. 主要なインストールパッケージ (`pkglist.txt`)
以下のツール群が標準でインストールされます。
- **コアツール**: `git`, `github-cli`, `ripgrep` (rg), `fd`, `fzf`, `jq`, `yazi`
- **開発環境**: `neovim`, `tmux`, `zsh`, `starship`, `zoxide`, `sheldon`
- **言語ランタイム**: `go`, `rustup`, `php`, `composer`, `deno`, `clojure`, `jdk-openjdk`
- **システム監視・便利ツール**: `bottom` (btm), `chafa`, `fastfetch`, `7zip`, `rsync`

## 4. 期待される挙動とワークフロー

### シェル環境 (Bash / Zsh)
- **Bash の役割**: `.bashrc` は `zsh` が利用可能な場合に即 `exec zsh` するランチャーとして機能します。Zsh が未インストールの場合のフォールバックとして `aliases.sh` の読み込みや `distrobox` 連携も担います。
- **プロンプト**: `starship` によるリッチで高速なプロンプト表示。`starship` が未インストールの場合は `vcs_info` を用いたシンプルなフォールバックプロンプトが有効になります。
- **プラグイン管理**: `sheldon` を使用してプラグインを管理。
- **コンテナ連携**: `distrobox` が利用可能な場合、自動的に `arch-dev` コンテナに `enter` する挙動が含まれています。`distrobox` は `pkglist.txt` に含まれておらず、`install.sh` ではインストールされないため、別途インストールが必要です。
- **履歴管理**: 共有履歴（SHARE_HISTORY）と重複無視（HIST_IGNORE_DUPS, HIST_IGNORE_SPACE）が設定されています。
- **NVM (Node Version Manager)**: `.zshrc` から `$HOME/.config/nvm` を参照していますが、`pkglist.txt` には含まれていないため、別途手動インストールが必要です。
- **モジュール構成**: エイリアスは `.config/shell/aliases.sh`、Zsh 関数は `.config/zsh/functions.zsh` に分離されています。

### セッション管理 (Tmux & Neovim)
- **自動セッション開始**: シェル起動時、インタラクティブ端末かつ Neovim 外（`$NVIM` 未設定）であれば、Tmux 外の場合は `main` セッションにアタッチまたは新規作成します（`exec tmux new-session -A -s main`）。
- **Neovim ターミナル**: Tmux 内でシェルが起動した際、`exec nvim -c "terminal" -c "file shell" -c "startinsert"` によって自動的に Neovim をターミナルモードで起動します。これにより、Neovim を IDE 兼ターミナルマルチプレクサとして活用するフローが期待されています。

### ファイル管理
- `yazi` がインストールされており、CLI 上での高速なファイルブラウジングが可能です。

## 5. メンテナンス
- 設定の変更は `~/dotfiles` 内で行い、`install.sh` を再実行することで環境に反映させます。
- パッケージの追加は `pkglist.txt` に追記してください。

## 6. AI アシスタント運用設計 (Claude & Gemini)

本リポジトリでは、CLIベースのAIアシスタント（Claude Code および Gemini CLI）の設定を管理しています。両者は**互いに一切の依存関係を持たず**、完全に独立した役割・領域で稼働するアーキテクチャ（疎結合）として設計されています。両者の接点はプロジェクトの `docs/` ディレクトリ（設計書）を介した非同期の連携のみです。

### 6.1. Gemini CLI（設計・思考特化）
Gemini は「**設計・思考フェーズ**」に専念します。
- **役割**: 要件定義、アーキテクチャ設計、仕様書の作成・更新、設計レビュー。
- **成果物**: `docs/` 配下のマークダウンドキュメント。
- **禁止事項**: 
  - `src/` や `tests/` など、実際のコードベースの直接的な編集および実装。
  - 実装のバグ修正やコードレベルのレビュー。
- **独立性**: Claude の存在やその固有設定を前提としたプロンプト・設定は含めません。

### 6.2. Claude Code（実装・品質特化）
Claude は「**実装・実行フェーズ**」に専念します。
- **役割**: 仕様に基づいたコードの実装、テストの記述（TDD厳守）、リファクタリング、バグ修正。
- **成果物**: `src/`、`tests/` などのソースコード。
- **禁止事項**: 
  - アーキテクチャの大幅な変更や仕様書の勝手な書き換え。
- **独立性**: Gemini の存在やその固有設定に依存せず、与えられた仕様書（ドキュメント）のみをインプットとして動作します。
