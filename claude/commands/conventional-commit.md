---
description: ローカルの変更を分析し、意味のある単位で分割コミット
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git diff:*), Bash(git restore:*)
---

## コンテキスト

- Git status: !`git status`
- ステージ済みの変更: !`git diff --cached --stat`
- 未ステージの変更: !`git diff --stat`
- 最近のコミット: !`git log --oneline -5`

## ルール

プロジェクトのルールに従うこと:
1. Conventional Commits 形式を使用: `type(scope): description`
2. 1コミット1タイプ - fix, feat, docs などを分ける
3. 小さく論理的な単位でコミット
4. `claude` のような汎用的なツール名を scope に使用しない

## タスク

ローカルの変更を分析し、意味のある単位で分割コミットを作成する:

1. **変更の分析**: 関連する変更をグループ化
   - ファイルの種類や場所（同じディレクトリや機能）
   - 変更の種類（feat, fix, docs, style, refactor など）
   - 論理的な関連性（一緒にコミットすべきファイル）

2. **コミットの計画**: 各グループに対して
   - 適切な Conventional Commits タイプを決定
   - 具体的な scope を選択（汎用的な名前は避ける）
   - 簡潔な説明を作成

3. **コミットの実行**: 各計画に対して
   - 関連するファイルのみをステージ
   - 適切なメッセージ形式でコミット作成
   - git status で確認

4. **報告**: 作成したコミットのサマリーを表示

確認なしで分析とコミットを進めること。
