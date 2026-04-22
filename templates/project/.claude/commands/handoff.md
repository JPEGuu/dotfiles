---
description: Gemini への引き継ぎコンテキストを生成し、gemini -p で直接セッションを起動する
allowed-tools: Read, Glob, Grep, Bash(git:*), Bash(gemini:*)
---

## 手順

### 1. 引き継ぎファイルの生成

`git log --oneline -5` と今セッションの作業内容を元に、`.agents/handoff/claude_to_gemini.md` を以下のテンプレートで**上書き**する：

```markdown
# Claude から Gemini への引き継ぎ事項

**日時**: （現在の日時）
**宛先**: Gemini
**送信元**: Claude

## 1. 本セッションの成果
<!-- 今回やったことを簡潔に -->

## 2. 現在のシステム状態
| 項目 | 状態 |
|------|------|
| テスト | passed / failed |
| 主要な変更 | — |

## 3. Gemini へのお願い
<!-- 設計レビュー、仕様追加、方針決定など -->

## 4. 注意事項
<!-- 既知の問題、制約事項など -->
```

### 2. Gemini セッションの起動

引き継ぎファイルを保存したら、以下のコマンドで Gemini に直接渡す：

```bash
gemini -p "$(cat .agents/handoff/claude_to_gemini.md)"
```

これにより Gemini が引き継ぎ内容を受け取った状態でセッションが始まる。
