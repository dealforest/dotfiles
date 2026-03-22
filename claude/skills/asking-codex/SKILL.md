---
name: asking-codex
description: Codex CLIを使って単発の質問や確認を行う。「Codexに質問」「Codexに聞いて」「Codexに確認して」「codex exec」と言及された時に使用。1回の実行で結果を返す。反復的なコードレビューにはreviewing-codexスキルを使用。
context: fork
allowed-tools: Bash(codex:*)
---

# Codex レビュー

Codex CLI を使ってコードレビューを受ける。

## ワークフロー

1. **実装の要約を作成**: 対象コードの目的、構造、主要な処理を簡潔にまとめる
2. **Codex にレビュー依頼**: 要約を渡してレビューを実行
3. **結果を出力**: Codex の指摘事項を表示

## 実行

```bash
codex exec "<実装の要約とレビュー依頼>"
```
