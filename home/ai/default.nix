# AI CLI 統合（Claude Code / OpenAI Codex）
#
# - claude-code / codex は nixpkgs 収録パッケージを使用（npm グローバル運用は廃止）。
# - Claude/Codex の共有コンテキストと各ツール固有設定をリンクする。
{ config, pkgs, ... }:

{
  home.packages = [
    pkgs.claude-code
    pkgs.codex
    pkgs.nodejs_22 # 開発・npm 実行用ランタイム（旧 nvm 廃止の代替）
  ];

  # --- Claude Code / Codex 設定 ---
  # 汎用の AI assistant 設定は git 管理し、個人用の蓄積情報はリポジトリ外に置く。
  # 実行中に即時反映・編集できるよう、dotfiles リポジトリへの可変 symlink にする。
  # 前提: この dotfiles リポジトリが ~/dotfiles に clone されていること。
  home.file =
    let
      claudeDir = "${config.home.homeDirectory}/dotfiles/home/ai/claude";
    in
    {
      ".claude/CLAUDE.md".source =
        config.lib.file.mkOutOfStoreSymlink "${claudeDir}/CLAUDE.md";
      ".codex/AGENTS.md".source =
        config.lib.file.mkOutOfStoreSymlink "${claudeDir}/CLAUDE.md";
      ".claude/commands".source =
        config.lib.file.mkOutOfStoreSymlink "${claudeDir}/commands";
      ".claude/agents".source =
        config.lib.file.mkOutOfStoreSymlink "${claudeDir}/agents";
    };
}
