# rtk (Rust Token Killer) 導入手順書

## 概要

Claude や Gemini などの AI CLI ツールのコンテキスト消費（トークン消費）を最適化・削減するためのツール `rtk` (https://github.com/rtk-ai/rtk) を現在の dotfiles 環境に導入する。

## 要件

1.  **インストール方法:** `cargo` を使用してインストールする。
    *   *注意:* `crates.io` に同名の別パッケージが存在するため、必ず GitHub リポジトリ (`--git https://github.com/rtk-ai/rtk`) を指定してインストールすること。
2.  **dotfiles への統合:**
    *   既存の `dotfiles/cargo-packages.txt` に依存関係として定義する。
    *   既存の `dotfiles/install.sh` を改修し、`cargo-packages.txt` に記述されたオプション（`--git ...` 等）を解釈して正しく `cargo install` できるようにする。
3.  **設定ファイルの管理:**
    *   `rtk` の設定ファイル (`~/.config/rtk/config.toml`) を `dotfiles/.config/rtk/config.toml` に配置し、既存のシンボリックリンク生成の仕組みに乗せる。
4.  **フックの有効化:**
    *   インストール後、Claude および Gemini 用の連携（初期化）を完了させる。

## 実装手順

### 1. `dotfiles/install.sh` の改修

現在の `install.sh` における `cargo install` 処理は `xargs -I{}` を用いているため、オプションを含む文字列が正しく解釈されない。これを `while read` ループを用いた処理に変更する。

**変更前のコード:**
```bash
# Install cargo packages
if command -v cargo >/dev/null 2>&1 && [ -f "$DOTFILES_DIR/cargo-packages.txt" ]; then
    echo "📦 Installing cargo packages..."
    if xargs -I{} cargo install {} < "$DOTFILES_DIR/cargo-packages.txt"; then
        echo "✅ Cargo packages installed."
    else
        echo "⚠️  WARNING: Some cargo packages failed to install." >&2
    fi
fi
```

**変更後のコード（要件を満たす実装例）:**
```bash
# Install cargo packages
if command -v cargo >/dev/null 2>&1 && [ -f "$DOTFILES_DIR/cargo-packages.txt" ]; then
    echo "📦 Installing cargo packages..."
    while IFS= read -r line || [ -n "$line" ]; do
        # 空行とコメント行(#で始まる行)をスキップ
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        
        # eval を使用するか、配列に展開して実行することで、引数を正しくパースさせる
        # eval "cargo install $line"
        # または、単に展開に任せる（ダブルクォートで囲まない）
        if ! cargo install $line; then
             echo "⚠️  WARNING: Failed to install: $line" >&2
        fi
    done < "$DOTFILES_DIR/cargo-packages.txt"
    echo "✅ Cargo packages installation process completed."
fi
```
*(※ Claude に依頼する際、上記の実装方針を伝え、最適なシェルスクリプトの実装を行わせること)*

### 2. `dotfiles/cargo-packages.txt` の更新

改修した仕組みを利用して、`rtk` のリポジトリパスを追記する。

**追加内容:**
```text
--git https://github.com/rtk-ai/rtk
```

### 3. rtk の手動インストールと設定ファイルの生成

スクリプト改修完了後（または改修のテストも兼ねて）、インストールを実行する。

```bash
# 修正した install.sh を実行するか、直接 cargo install を実行
cargo install --git https://github.com/rtk-ai/rtk

# 設定ファイルの初期生成
rtk config --create
```
これにより、`~/.config/rtk/config.toml` が作成される。

### 4. 設定ファイルの dotfiles への取り込み

生成された設定ファイルを `dotfiles` リポジトリ側に移動し、管理対象とする。

```bash
mkdir -p ~/dotfiles/.config/rtk
mv ~/.config/rtk/config.toml ~/dotfiles/.config/rtk/
```
*(次回の `install.sh` 実行時、または手動でシンボリックリンクが作成されるようにする)*

### 5. AI アシスタント用フックの有効化

インストールした `rtk` を Claude および Gemini CLI に認識させるため、初期化コマンドを実行する。

```bash
rtk init --claude
rtk init --gemini
```
これにより、各ツールの設定ファイル（`.claude.json` や `.gemini/settings.json` など）が更新され、コマンド実行時に `rtk` が介入するようになる。
