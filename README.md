# dotfiles

---

## ディレクトリ構成

```
dotfiles/
├── flake.nix                           # エントリポイント（nixosConfigurations.wsl / .desktop）
├── flake.lock                          # 入力リビジョン固定
├── config.nix                          # ユーザー名・ホームパス・git identity
├── hosts/
│   ├── wsl/default.nix                 # WSL 固有（wsl.enable, defaultUser）
│   └── desktop/
│       ├── default.nix                 # bare-metal 固有（systemd-boot, networkmanager, my.gui.enable=true）
│       └── hardware-configuration.nix  # ⚠️ 実機で生成して置き換える
├── nixos/
│   ├── common.nix                      # 両環境共通（nix flakes, allowUnfree, user, zsh, docker, ssh, locale）
│   └── gui.nix                         # GUI システム層（my.gui.enable: niri / ly / PipeWire / フォント / polkit）
└── home/                               # Home Manager
    ├── default.nix                     # HM エントリ（imports 集約）
    ├── packages.nix                    # home.packages（ユーザー向け CLI ツール）
    ├── shell.nix                       # zsh / 環境変数 / エイリアス / SKK辞書
    ├── programs.nix                    # starship / zoxide / fzf / git の enable
    ├── ai/
    │   ├── default.nix                 # codex + AI assistant 設定
    │   └── codex/                      # Codex 設定 / custom agents / skills
    │       ├── AGENTS.md
    │       ├── config.toml
    │       ├── agents/
    │       └── skills/
    ├── nvim/                           # Neovim 設定（raw config co-location）
    ├── tmux/                           # tmux 設定
    ├── yazi/                           # yazi 設定
    ├── starship/                       # starship.toml
    ├── clojure/                        # deps.edn / tools
    └── gui/                            # GUI ユーザー層（wezterm / niri / Noctalia。osConfig.my.gui.enable で分岐）
```

## セットアップ

**まず `config.nix` を自分の情報に書き換える。** ここで定義した値がユーザー名・ホーム
ディレクトリ・git identity として flake 全体（`home/` / `nixos/` / `hosts/wsl`）へ反映される。

### 個人設定（config.nix）

`config.nix` は個人依存の値を集約した単一ソース。以下を自分用に編集する。

```nix
{
  username      = "your-name";        # ログインユーザー名（system user / home-manager / wsl.defaultUser 共通）
  homeDirectory = "/home/your-name";  # username に合わせる（/home/<username>）
  description   = "your-name";        # ユーザーの表示名（任意）

  git = {
    name  = "Your Name";              # git のコミット著者名
    email = "you@example.com";        # git のコミット著者メール（GitHub の noreply 推奨）
  };
}
```

- `username` を変えたら `homeDirectory` も `/home/<username>` に合わせる。
- 最終的に dotfiles は自分の `homeDirectory` 配下（既定 `~/dotfiles`）へ置く
  （`home/ai` と `home/nvim` の symlink が `~/dotfiles/...` の絶対パス前提のため）。
- git メールは実アドレスを晒したくない場合、GitHub の noreply
  （`<numeric-id>+<login>@users.noreply.github.com`）を使う。

### WSL（NixOS-WSL）

初回は自分のユーザーがまだ無く、NixOS-WSL の既定ユーザー（通常 `nixos`）で起動するため、
2 段階で構築する。

```bash
# --- 初回のみ ---
# 1. 既定ユーザーで clone（この時点では初期ユーザーの home 配下でよい）
git clone https://github.com/JPEGuu/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 2. config.nix を自分の情報に編集
$EDITOR config.nix

# 3. rebuild で自分のユーザーと /home/<username> を生成
sudo nixos-rebuild switch --flake .#wsl

# 4. WSL を終了して入り直し、自分のユーザーでログインする
#    （Windows 側 PowerShell 例: wsl -t NixOS  →  wsl -d NixOS）

# 5. 編集済みの dotfiles を自分の home 配下へ移し、所有権を移す
#    （初期ユーザー名が nixos 以外なら読み替える）
sudo mv /home/nixos/dotfiles ~/dotfiles
sudo chown -R "$USER:$(id -gn)" ~/dotfiles
cd ~/dotfiles

# 6. 自分のユーザーで再反映
sudo nixos-rebuild switch --flake .#wsl
```

2 回目以降は `config.nix` は編集済みのため、下記「設定の更新」の `nrs-wsl` を使う。

### bare-metal（実機）

NixOS インストール時に自分のユーザーを作成し、そのユーザーでログインできる状態から始める
（`config.nix` の `username` はそのユーザー名に合わせる）。

```bash
# 1. 自分の home に clone
git clone https://github.com/JPEGuu/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 2. config.nix を自分の情報に編集（username はログインユーザーと一致させる）
$EDITOR config.nix

# 3. hardware-configuration.nix を実機の出力で置き換える
sudo nixos-generate-config --show-hardware-config > hosts/desktop/hardware-configuration.nix

# 4. ビルド & 切り替え
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
