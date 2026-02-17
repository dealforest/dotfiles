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
- **PR のマージは絶対に行わない**（`gh pr merge` の実行禁止）

## Issue 番号の自動リンク

ブランチ名に issue 番号が含まれている場合（例: `feature/566_batch_size_limit`, `fix/123-bug-title`）、PR 本文の先頭に `- fix #<issue番号>` を追加する。

- ブランチ名からの番号抽出パターン: `feature/<数字>`, `fix/<数字>`, `hotfix/<数字>` など、`/` の直後にある数字
- 例: `feature/566_batch_size_limit` → `- fix #566`
- 例: `fix/123-bug-title` → `- fix #123`

## Worktree 対応

- **git worktree 内で起動された場合、全ての git 操作はその worktree 内で実行すること**
- 親リポジトリ（`.worktree/` の親ディレクトリ）でプッシュやPR操作を行ってはいけない
- `git rev-parse --show-toplevel` で現在の worktree ルートを確認し、そのディレクトリ内で操作する
