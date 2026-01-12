---
description: コミット済みの変更をリモートにプッシュ
allowed-tools: Bash(git push:*), Bash(git status:*), Bash(git log:*), Bash(git remote:*), Bash(gh pr view:*)
---

## コンテキスト

- 現在のブランチ: !`git branch --show-current`
- リモートより先のコミット: !`git log --oneline @{u}..HEAD 2>/dev/null || echo "upstream ブランチなし"`
- Git status: !`git status --short`

## タスク

コミット済みの変更をリモートリポジトリにプッシュする。

1. プッシュすべきコミットがあるか確認
2. 未プッシュのコミットがあればリモートにプッシュ
3. 結果を報告
4. リモートリポジトリの URL を表示（PR がある場合は PR の URL も）

変更のコミットは行わない。既存のコミットのプッシュのみ。
