# PR レビュー操作リファレンス（高度な操作）

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
