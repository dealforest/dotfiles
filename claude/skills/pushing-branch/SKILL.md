---
name: pushing-branch
description: コミット済みの変更をリモートにプッシュし、PRを作成・更新する。「プッシュ」「push」「リモートに反映」「PRを作成」「PR作って」「プルリクエスト」「リモートに上げて」「pushして」と言及された時に使用。コミット作成は対象外。PRのレビューやマージは対象外。
context: fork
agent: general-purpose
allowed-tools: Bash(git push:*), Bash(git status:*), Bash(git log:*), Bash(git remote:*), Bash(gh:*)
---

# ブランチのプッシュと PR 管理

## 対象ブランチの決定

- 引数あり（例: `/pushing-branch feature/maestro`）: 指定されたブランチを対象にする。**checkout は不要**。各コマンドでブランチ名を明示的に指定する。
  - プッシュ: `git push origin feature/maestro`
  - ログ確認: `git log origin/develop..feature/maestro`
  - PR 作成: `gh pr create --head feature/maestro`
  - PR 確認: `gh pr list --head feature/maestro`
- 引数なし（例: `/pushing-branch`）: 現在のブランチを対象にする

## ワークフロー

1. 対象ブランチを決定する（引数があればそのブランチ、なければ現在のブランチ）
2. プッシュすべきコミットがあるか確認
3. 未プッシュのコミットがあればリモートにプッシュ
4. PR の存在確認
   - PR がある場合: PR の詳細を更新
   - PR がない場合: 新規 PR を作成
5. 結果を報告

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
