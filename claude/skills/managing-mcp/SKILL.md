---
name: managing-mcp
description: mmcp を使って MCP サーバーを追加・削除・管理する。MCP 追加、MCP 削除、MCP 管理と言及された時に使用。
context: fork
allowed-tools: Bash(npx mmcp:*), Read, Edit
---

# MCP サーバー管理

mmcp を使って MCP サーバーを管理する。

## 設定ファイル

- `~/.mmcp.json` → `mmcp/mmcp.json` へのシンボリックリンク
- 適用先エージェント: claude-code, codex-cli, gemini-cli

### 設定ファイルの構造

```json
{
  "mode": "merge",
  "agents": ["claude-code", "codex-cli", "gemini-cli"],
  "mcpServers": {
    "<server-name>": {
      "command": "<command>",
      "args": ["<arg1>", "<arg2>"],
      "env": {}
    }
  }
}
```

- `mode`: `merge`（既存設定に追加）または `replace`（既存設定を上書き）
- `agents`: `apply` 時の適用対象エージェント一覧

## コマンド一覧

### 一覧表示

```bash
npx mmcp list
npx mmcp list --json  # JSON 形式で出力
```

### 追加

```bash
npx mmcp add <name> <command> [args...]

# 例: npx ベースの MCP サーバー
npx mmcp add context7 npx -y @upstash/context7-mcp@latest

# 環境変数付き
npx mmcp add myserver npx my-mcp -e API_KEY=xxx

# 同名サーバーを上書き
npx mmcp add --force context7 npx -y @upstash/context7-mcp@latest
```

### 削除

```bash
npx mmcp remove <name>
```

### エージェント管理

```bash
npx mmcp agents list           # 適用対象エージェント一覧
npx mmcp agents add <name...>  # エージェントを追加
npx mmcp agents remove <name...>  # エージェントを削除
```

対応エージェント: claude-code, claude-desktop, codex-cli, cursor, gemini-cli, github-copilot-cli

### 設定を適用

```bash
npx mmcp apply                      # 全エージェントに適用
npx mmcp apply --agents claude-code # 特定エージェントのみ
npx mmcp apply --mode replace       # 既存設定を上書き
```

追加・削除後は `apply` で各エージェントに設定を反映する。

## Docker ベースの MCP サーバー

`mmcp add` は Docker 用の専用オプションがないため、Docker ベースのサーバーは `mmcp/mmcp.json` を直接編集する。

### 設定例

```json
"xcodeproj": {
  "command": "docker",
  "args": [
    "run", "--rm", "-i",
    "-v", "${PWD}:/workspace",
    "ghcr.io/giginet/xcodeproj-mcp-server",
    "/workspace"
  ]
}
```

### 環境変数の展開ルール

MCP サーバーの args 内で環境変数を使う場合、**エージェントごとに展開ルールが異なる**:

| 記法 | Claude Code | VS Code 系 (Cursor 等) |
|------|-------------|----------------------|
| `${PWD}` | 展開される | 展開される |
| `$PWD` | 展開されない | 展開されない |
| `${workspaceFolder}` | 展開されない (VS Code 専用) | 展開される |

- Claude Code は `${VAR}` 形式のシェル環境変数のみ展開する
- `${workspaceFolder}` は VS Code 専用変数のため Claude Code では使えない
- **Docker のボリュームマウントには `${PWD}` を使うこと**
