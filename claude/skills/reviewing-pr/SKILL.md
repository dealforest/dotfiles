---
name: reviewing-pr
description: GitHub PRの情報取得、差分確認、コメント操作を行う。PRレビュー、コードレビュー、PR操作と言及された時に使用。
context: fork
agent: general-purpose
allowed-tools: Bash(gh:*), Bash(awk:*)
---

# PR レビュー操作

GitHub CLI (`gh`) を使った PR レビュー操作。

## 操作一覧

1. **PR情報取得**: タイトル、本文、状態、ブランチ情報
2. **差分取得**: 行番号付きで表示（L=削除行、R=追加行）
3. **コメント取得**: PR全体とコード行へのコメント
4. **コメント投稿**: ユーザーの許可後のみ実行
5. **インラインコメント**: 特定のコード行にコメント
6. **コメント返信**: 既存コメントへの返信

## ルール

- コメント操作はユーザーの許可後のみ実行
- PR URL から OWNER/REPO/NUMBER を抽出して使用

詳細なコマンド例は [REFERENCE.md](REFERENCE.md) を参照。
