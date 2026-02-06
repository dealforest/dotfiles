---
name: managing-mcp
description: mmcp を使って MCP サーバーを追加・削除・管理する。MCP 追加、MCP 削除、MCP 管理と言及された時に使用。
context: fork
allowed-tools: Bash(npx mmcp:*)
---

# MCP サーバー管理

mmcp を使って MCP サーバーを管理する。

## コマンド一覧

### 一覧表示

```bash
npx mmcp list
```

### 追加

```bash
npx mmcp add <name> <command> [args...]

# 例: context7 を追加
npx mmcp add context7 npx -y @upstash/context7-mcp@latest

# 例: playwright を追加
npx mmcp add playwright npx -y @playwright/mcp@latest

# 環境変数付きで追加
npx mmcp add myserver npx my-mcp -e API_KEY=xxx
```

### 削除

```bash
npx mmcp remove <name>

# 例
npx mmcp remove playwright
```

### 設定を適用

```bash
npx mmcp apply
```

追加・削除後は `apply` で各エージェントに設定を反映する。

## 設定ファイル

- `~/.mmcp.json` - mmcp の設定ファイル
- 適用先: claude-code, codex-cli, gemini-cli
