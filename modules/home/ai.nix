# AI CLI 統合（Claude Code / OpenAI Codex）
#
# - claude-code / codex は nixpkgs 収録パッケージを使用（npm グローバル運用は廃止）。
# - Claude Code のグローバル設定をリンク。settings.json はアプリ自身が書き込む
#   （model/effort 等）ため、read-only な store リンクではなく dotfiles リポジトリへの
#   可変 symlink にする。
{ config, pkgs, ... }:

{
  home.packages = [
    pkgs.claude-code
    pkgs.codex
    pkgs.nodejs_22 # 開発・npm 実行用ランタイム（旧 nvm 廃止の代替）
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
}
