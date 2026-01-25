---
name: pushing-branch
description: コミット済みの変更をリモートリポジトリにプッシュする。プッシュ、push、リモートに反映と言及された時に使用。
context: fork
agent: general-purpose
allowed-tools: Bash(git push:*), Bash(git status:*), Bash(git log:*), Bash(git remote:*), Bash(gh pr view:*)
---

# ブランチのプッシュ

## ワークフロー

1. プッシュすべきコミットがあるか確認
2. 未プッシュのコミットがあればリモートにプッシュ
3. 結果を報告
4. リモートリポジトリの URL を表示（PR がある場合は PR の URL も）

## ルール

- 変更のコミットは行わない
- 既存のコミットのプッシュのみ
