# PR レビュー操作リファレンス

## PR情報取得

```bash
gh pr view NUMBER --repo OWNER/REPO --json title,body,author,state,baseRefName,headRefName,url
```

## 差分取得（行番号付き）

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

## コメント取得

Issue Comments:
```bash
gh api repos/OWNER/REPO/issues/NUMBER/comments --jq '.[] | {id, user: .user.login, created_at, body}'
```

Review Comments:
```bash
gh api repos/OWNER/REPO/pulls/NUMBER/comments --jq '.[] | {id, user: .user.login, path, line, created_at, body, in_reply_to_id}'
```

## PRにコメント

```bash
gh pr comment NUMBER --repo OWNER/REPO --body "コメント内容"
```

## インラインコメント

head commit SHA を取得:
```bash
gh api repos/OWNER/REPO/pulls/NUMBER --jq '.head.sha'
```

単一行:
```bash
gh api repos/OWNER/REPO/pulls/NUMBER/comments \
  --method POST \
  -f body="コメント" \
  -f commit_id="SHA" \
  -f path="src/example.py" \
  -F line=15 \
  -f side=RIGHT
```

複数行（10〜15行目）:
```bash
gh api repos/OWNER/REPO/pulls/NUMBER/comments \
  --method POST \
  -f body="コメント" \
  -f commit_id="SHA" \
  -f path="src/example.py" \
  -F line=15 \
  -f side=RIGHT \
  -F start_line=10 \
  -f start_side=RIGHT
```

**注意**: `-F` は数値パラメータに使用

## コメントへ返信

```bash
gh api repos/OWNER/REPO/pulls/NUMBER/comments/COMMENT_ID/replies \
  --method POST \
  -f body="返信内容"
```
