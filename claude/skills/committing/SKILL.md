---
name: committing
description: Conventional Commits形式でgitコミットを作成する。コミット、commit、変更をコミットと言及された時に使用。
context: fork
agent: general-purpose
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git diff:*), Bash(git restore:*), Bash(git log:*)
---

# コミット作成

## ワークフロー

1. `git diff` で変更内容を確認
2. **各 hunk（変更ブロック）を分析し、それぞれの「動作・振る舞い」を特定**
3. **動作ごとにグループ化**（「〜する」で説明できる単位）
4. 各グループに Conventional Commits タイプを決定
5. **`git add -p` で hunk 単位でステージし、グループごとにコミット**
6. 全グループをコミットし終えたらサマリーを表示

## 分割の判断基準

### 必ず分けるケース
- **異なる「動作」は別コミット**
  - 「読み込む」と「保存する」は別
  - 「追加する」と「削除する」は別
  - 「表示する」と「非表示にする」は別
- **コミットメッセージの body に複数の箇条書きを書きたくなったら分割のサイン**
- Conventional Commits タイプが異なる場合

### 同じコミットにまとめてよいケース
- 1つの動作を実現するために必要な複数の変更（import文とその使用箇所など）
- 同じ目的の同じ種類の変更（複数ファイルの同じリファクタリングなど）

## git add -p の使い方

```bash
# hunk ごとに y/n で選択
git add -p <file>
# y: ステージする
# n: スキップ
# s: さらに細かく分割

# ステージ後にコミット
git commit -m "type: description"

# 残りの変更を次のコミットへ
git add -p <file>
git commit -m "type: description"
```

## ルール

- Conventional Commits 形式: `type: description`
- **1コミット = 1動作（「〜する」で表現できる1つの振る舞い）**
- description だけで変更内容が伝わるようにする（body は補足のみ）
- 迷ったら分割（後から squash は簡単、分割は難しい）

確認なしで分析とコミットを進めること。
