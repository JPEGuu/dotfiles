---
description: プロジェクトセッション終了。変更棚卸し・docs同期確認・コミット確認
allowed-tools: Read, Glob, Grep, Bash(git:*)
---

## プロジェクトセッション終了

### 1. 変更棚卸し
```
git diff --stat
git status
```

### 2. docs/ 同期確認
`src/` の実装と `docs/` の仕様にズレがないか確認する。
ズレがあれば報告する。

### 3. コミット確認
未コミットの変更がある場合、ユーザーにコミットを促す。
