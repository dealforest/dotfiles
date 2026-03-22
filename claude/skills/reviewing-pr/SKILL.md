---
name: reviewing-pr
description: GitHub PRの情報取得、差分確認、コメント投稿・返信を行う。「PRレビュー」「コードレビュー」「PRの差分を見て」「PRにコメント」「PRを確認して」「レビューコメント」「PRの内容を教えて」「PR操作」と言及された時に使用。PRの作成やプッシュは対象外。
context: fork
agent: general-purpose
allowed-tools: Bash(gh:*), Bash(awk:*)
---

# PR レビュー操作

GitHub CLI (`gh`) を使った PR レビュー操作。

## 基本コマンド

### PR情報取得

```bash
gh pr view NUMBER --repo OWNER/REPO --json title,body,author,state,baseRefName,headRefName,url
```

### 差分取得（行番号付き）

```bash
gh pr diff NUMBER --repo OWNER/REPO | awk '
/^@@/ {
  match($0, /-([0-9]+)/, old)
  match($0, /\+([0-9]+)/, new)
  old_line = old[1]
  new_line = new[1]
  print $0
  next
}
/^-/ { printf "L%-4d     | %s\n", old_line++, $0; next }
/^\+/ { printf "     R%-4d| %s\n", new_line++, $0; next }
/^ / { printf "L%-4d R%-4d| %s\n", old_line++, new_line++, $0; next }
{ print }
'
```

- `L数字`: LEFT(base)側 → `side=LEFT`
- `R数字`: RIGHT(head)側 → `side=RIGHT`

### コメント取得

```bash
# Issue Comments
gh api repos/OWNER/REPO/issues/NUMBER/comments --jq '.[] | {id, user: .user.login, created_at, body}'

# Review Comments
gh api repos/OWNER/REPO/pulls/NUMBER/comments --jq '.[] | {id, user: .user.login, path, line, created_at, body, in_reply_to_id}'
```

### PRにコメント

```bash
gh pr comment NUMBER --repo OWNER/REPO --body "コメント内容"
```

## ルール

- コメント操作はユーザーの許可後のみ実行
- PR URL から OWNER/REPO/NUMBER を抽出して使用

インラインコメント・返信など高度な操作は [REFERENCE.md](REFERENCE.md) を参照。
