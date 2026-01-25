---
name: committing
description: Conventional Commits形式でgitコミットを作成する。コミット、commit、変更をコミットと言及された時に使用。
context: fork
agent: general-purpose
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git diff:*), Bash(git restore:*), Bash(git log:*)
---

# コミット作成

## ワークフロー

1. 変更を分析してグループ化
2. 各グループに Conventional Commits タイプを決定
3. 関連ファイルをステージしてコミット作成
4. 作成したコミットのサマリーを表示

## ルール

- Conventional Commits 形式: `type: description`
- 1コミット1タイプ（fix, feat, docs などを分ける）
- 小さく論理的な単位でコミット

確認なしで分析とコミットを進めること。
