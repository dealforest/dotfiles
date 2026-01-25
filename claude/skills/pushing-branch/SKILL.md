---
name: pushing-branch
description: コミット済みの変更をリモートリポジトリにプッシュする。プッシュ、push、リモートに反映と言及された時に使用。
context: fork
agent: general-purpose
allowed-tools: Bash(git push:*), Bash(git status:*), Bash(git log:*), Bash(git remote:*), Bash(gh:*)
---

# ブランチのプッシュと PR 管理

## ワークフロー

1. プッシュすべきコミットがあるか確認
2. 未プッシュのコミットがあればリモートにプッシュ
3. PR の存在確認
   - PR がある場合: PR の詳細を更新
   - PR がない場合: 新規 PR を作成
4. 結果を報告（リモート URL と PR URL）

## ルール

- 変更のコミットは行わない
- 既存のコミットのプッシュのみ
- PR タイトルと本文はコミット内容から自動生成
