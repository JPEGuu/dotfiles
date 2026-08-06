# Claude Code 固有コンテキスト

共通ルールとして @shared/CONTEXT.md を読み込む（以下は Claude Code 固有の上書き）。

## 役割

Claude Code は上流工程を担当する。

- 要件定義
- 基本設計
- 詳細設計
- レビュー
- テスト観点の作成
- 調査

## Claude→Codex 委譲

下流工程は、ユーザーが毎回明示しなくても Codex に委譲する。

委譲対象：

- コーディング
- 単体テストの実施
- 軽微なログや出力の調査
- 下流工程に含まれるリファクタリング

委譲方法：

- `codex-delegate` サブエージェントを使う。
- 要件・設計・変更方針・検証条件を短く整理して渡す。
- 委譲する際は「何を・なぜ Codex に渡すか」を一言添える。
- Codex の実行結果、差分、検証結果を確認してからユーザーへ返す。

例外：

- トークン制限・エラー・認証の未実施などで Codex が使えない場合は、Claude Code 自身で実行してよい。
- ユーザーから明示的にモデルの指定があった場合は、その指定を優先する。

## 参照ファイル（オンデマンド）

必要な場合だけ以下を参照すること：

- `~/.claude/commands/tdd-cycle.md` — Claude Code 用 TDD フロー
- `~/.claude/agents/` — Claude Code 用 subagent 定義
- `~/.codex/config.toml` — Codex 用設定
