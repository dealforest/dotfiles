---
name: flowchart
description: 自然言語やMermaid記法からVisio風スイムレーンフローチャートSVGを生成する。「フローチャート生成」「SVGフローチャート」「スイムレーン図」「フローをまとめて」「処理の流れ」「フロー図を作って」「図にして」「処理フローを可視化」「ワークフロー図」と言及された時に使用。コードベースの処理フロー可視化にも対応。
context: fork
agent: general-purpose
allowed-tools: Bash(python3:*), Read, Write, Glob, Grep
---

# Flowchart SVG Generator

Visio 風スイムレーンフローチャート SVG 生成スキル。
ユーザーの自然言語の説明から中間 JSON を構築し、Sugiyama レイアウトエンジンで SVG を生成する。

## 引数

スキル呼び出し時の引数はフローの説明。以下のいずれかの形式:

- **自然言語**: `「動画生成完了するまでのフロー」`
- **Mermaid 記法**: sequenceDiagram や flowchart TD
- **箇条書き**: ステップの列挙

引数がない場合はユーザーに何のフローを図にしたいか確認する。

## ワークフロー

### Step 1: フローの理解

引数の内容に応じてフローを理解する:

- **コードベースの処理フロー** の場合 → Glob/Grep/Read でソースコードを読み、実際の処理の流れを把握
- **概念的なフロー** の場合 → 引数の説明から関係者・ステップ・分岐を整理
- **Mermaid 記法** の場合 → そのまま中間 JSON に変換

### Step 2: 中間 JSON を生成

フローの理解をもとに中間 JSON を `/tmp/flowchart-output/<name>.json` に書き出す。

```json
{
  "title": "フロー名",
  "participants": [
    {"id": "p1", "name": "表示名", "icon": "user"}
  ],
  "steps": [
    {"id": "s1", "participant": "p1", "text": "ステップ名", "type": "process"}
  ],
  "arrows": [
    {"from": "s1", "to": "s2", "label": null, "branch": null}
  ]
}
```

### Step 3: SVG を生成

```bash
mkdir -p /tmp/flowchart-output
python3 ~/.claude/skills/flowchart/generate_flowchart.py /tmp/flowchart-output/<name>.json /tmp/flowchart-output/<name>.svg
```

### Step 4: ブラウザで開く

```bash
open -a "Google Chrome" /tmp/flowchart-output/<name>.svg
```

## JSON 設計ガイドライン

### participants

フローに関わるアクター・システムをスイムレーンとして定義。

| フィールド | 説明 |
|-----------|------|
| `id` | 一意の識別子（英数字） |
| `name` | スイムレーンヘッダーの表示名 |
| `icon` | アイコン種別 |

**icon 一覧**: `user`, `server`, `database`, `ai`, `cloud`, `mobile`, `payment`, `email`, `shield`, `gear`, `document`, `clock`

### steps

| フィールド | 説明 |
|-----------|------|
| `id` | 一意の識別子 |
| `participant` | 所属する participant の id |
| `text` | ステップの表示テキスト（簡潔に） |
| `type` | ノードの種別（下表参照） |

**type 一覧**:

| type | 描画 | 用途 |
|------|------|------|
| `start` | ピル（青） | フローの開始点 |
| `end` | ピル（青） | フローの終了点 |
| `process` | 角丸ボックス（白） | 一般的な処理 |
| `internal` | 角丸ボックス（淡いブルー） | 内部処理・自動処理 |
| `external` | 角丸ボックス（淡いグリーン） | 外部入出力・API 呼び出し |
| `condition` | ダイヤモンド（紫枠） | 条件分岐 |

### arrows

| フィールド | 説明 |
|-----------|------|
| `from` | 始点 step の id |
| `to` | 終点 step の id |
| `label` | 矢印上のラベル（不要なら `null`） |
| `branch` | `null`=通常, `"yes"`=条件Yes, `"no"`=条件No |

### 設計のコツ

- **participant は 3〜5 が最適**（2 だと単純すぎ、6 以上は幅が広くなりすぎる）
- **step のテキストは 10 文字前後**（長いと折り返される）
- **condition の後は必ず yes/no の 2 本の arrow** を定義
- **internal は自システム内の処理**、**external は他システムとのやりとり** で使い分け

## スクリプトの場所

```
~/.claude/skills/flowchart/generate_flowchart.py
```
