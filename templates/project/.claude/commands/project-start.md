---
description: プロジェクトセッション開始。引き継ぎ確認・docs読み込み・git状態確認・タスク確認
allowed-tools: Read, Glob, Grep, Bash(git:*)
---

## プロジェクトセッション開始

### 1. 引き継ぎ確認
`.agents/handoff/gemini_to_claude.md` を読み込む（存在する場合）。

### 2. docs 読み込み
`docs/` 配下の仕様ファイルを確認する。

### 3. git 状態確認
```
git status
git log --oneline -5
```

### 4. タスク確認
引き継ぎファイルまたはユーザー指示から今セッションのタスクを把握し、報告する。
