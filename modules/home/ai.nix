# AI CLI 統合（Claude Code / OpenAI Codex / rtk）
#
# - claude-code / codex は nixpkgs 収録パッケージを使用（npm グローバル運用は廃止）。
# - rtk は nixpkgs 未収録のため pkgs/rtk.nix を callPackage でビルド。
# - Claude Code のグローバル設定をリンク。settings.json はアプリ自身が書き込む
#   （model/effort 等）ため、read-only な store リンクではなく dotfiles リポジトリへの
#   可変 symlink にする。
{ config, pkgs, lib, ... }:

# let
#   rtk = pkgs.callPackage ../../pkgs/rtk.nix { };
# in
{
  home.packages = [
    pkgs.claude-code
    pkgs.codex
    pkgs.nodejs_22 # 開発・npm 実行用ランタイム（旧 nvm 廃止の代替）
    # rtk
  ];

  # --- Claude Code グローバル設定 ---
  home.file = {
    # read-only で問題ないもの（store リンク）
    ".claude/CLAUDE.md".source = ../../claude/CLAUDE.md;
    ".claude/commands".source = ../../claude/commands;
    ".claude/agents".source = ../../claude/agents;

    # Claude Code が書き込むため可変 symlink にする。
    # 前提: この dotfiles リポジトリが ~/dotfiles に clone されていること。
    ".claude/settings.json".source =
      config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/dotfiles/claude/settings.json";
  };

  # --- rtk の Claude Code 連携フック初期化 ---
  # activation 時に実行（home.packages の rtk が PATH に入った後）。
  # (RTK が無効化されているため、現在はコメントアウト)
  # home.activation.rtkInit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  #   if command -v rtk >/dev/null 2>&1; then
  #     $DRY_RUN_CMD rtk init -g --claude-md || true
  #   fi
  # '';
}
