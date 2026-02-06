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
4. 結果を報告

## 結果の報告

プッシュ完了後、以下を必ず表示する:

- プッシュしたコミット一覧（ハッシュと内容）
- PR が存在する場合: **PR の URL を必ず表示する**（`gh pr view --json url -q .url` で取得）

## ルール

- 変更のコミットは行わない
- 既存のコミットのプッシュのみ
- PR タイトルと本文はコミット内容から自動生成
