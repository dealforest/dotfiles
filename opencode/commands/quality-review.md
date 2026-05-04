---
description: 実装完了後の品質レビューパイプラインを実行する
---

Agent Teams 機能を使い、品質チームを構成してレビューを並列実行する。
各チームメイトは独立した Claude Code セッションとして動作し、共有タスクリストで進捗を管理する。

> **トークンコスト**: 各チームメイトが独立したコンテキストウィンドウを持つため、単一セッションより大幅にトークンを消費する。レビュー・調査タスクでは通常この追加コストは価値がある。

## Step 1: 変更分析

### ベースブランチの特定

```bash
git log --oneline develop..HEAD
```

develop からの差分がない場合は、直近のコミットを対象にする。

### 変更ファイルの取得

```bash
git diff --name-only develop...HEAD
```

### 変更種別の判定

変更ファイルパスから以下を判定する：

| パターン | フラグ |
|---------|-------|
| `mood-board-firebase/` にマッチ | `HAS_FIREBASE=true` |
| `mood-board-app/**/screens/**` or `mood-board-app/**/components/**` の `.tsx`/`.ts` | `HAS_UI=true` |
| `mood-board-app/` にマッチ（上記以外含む） | `HAS_MOBILE=true` |

### feature 名の特定

ブランチ名から推定する（`feature/xxx` → `xxx`）。artifacts パスに使用。

## Step 2: チーム作成とタスク定義

### 2-1. TeamCreate でチームを作成

```
TeamCreate:
  team_name: "quality-review"
  description: "品質レビューパイプライン: <feature名>"
```

### 2-2. TaskCreate でタスクを作成

判定結果に応じて以下のタスクを作成する。チームメイトあたり1〜2タスクが適切。

**タスク A: コードレビュー + セキュリティ**（常に作成）

```
TaskCreate:
  subject: "コードレビュー + セキュリティチェック"
  description: |
    develop ブランチからの変更を対象にコードレビューとセキュリティチェックを実行。
    変更ファイル: <変更ファイル一覧>

    チェック項目:
    - 型安全性（TypeScript strict mode 準拠）
    - エラーハンドリングの適切さ
    - DRY 原則（既存ユーティリティの再利用）
    - XSS / インジェクション / 認証・認可の問題
    - 機密データ露出（API キー、トークン）
    - Firebase セキュリティルールとの整合性
    - 課金・クレジット消費のトランザクション安全性
      （消費と処理が原子的か、失敗時にロールバック/返却されるか）

    出力: severity (critical/warning/info) 付きの指摘リスト。
    完了後、TaskUpdate で completed に更新し、チームリーダーに SendMessage で結果を報告すること。
  activeForm: "コードレビュー実行中"
```

**タスク B-1: Firebase テスト**（HAS_FIREBASE=true の場合）

```
TaskCreate:
  subject: "Firebase Functions テスト実行 + E2E レビュー"
  description: |
    Firebase Functions の変更に対するテスト実行と E2E レビュー。
    変更ファイル: <Firebase 関連の変更ファイル一覧>

    実行内容:
    1. cd mood-board-firebase/functions && npm test でテスト実行
    2. テストカバレッジ確認（変更箇所に対応するテストがあるか）
    3. モック禁止（実 Emulator を使用しているか）確認
    4. テスト結果を .artifacts/<feature>/test-results/ に保存

    出力: テスト結果サマリ + エビデンスファイルパス。
    完了後、TaskUpdate で completed に更新し、チームリーダーに SendMessage で結果を報告すること。
  activeForm: "Firebase テスト実行中"
```

**タスク B-2: Maestro E2E テスト**（HAS_MOBILE=true の場合）

このタスクは作成前に **ユーザーに確認** する。
確認メッセージ: 「モバイルの変更があります。Maestro E2E テストを実行しますか？（シミュレータが必要です）」

```
TaskCreate:
  subject: "Maestro E2E テスト実行"
  description: |
    モバイルアプリの変更に対する Maestro E2E テスト実行。
    /maestro-e2e-runner スキルを使用して全フローを実行。
    結果を .artifacts/<feature>/test-results/ に保存。

    出力: テスト結果サマリ + 録画ファイルパス。
    完了後、TaskUpdate で completed に更新し、チームリーダーに SendMessage で結果を報告すること。
  activeForm: "Maestro E2E テスト実行中"
```

**タスク C: UI/UX レビュー**（HAS_UI=true の場合）

```
TaskCreate:
  subject: "UI/UX レビュー"
  description: |
    UI 変更に対するレビュー。
    変更ファイル: <UI 関連の変更ファイル一覧>

    チェック項目:

    【重点】ユーザーフローの安全性（課金・不可逆操作）
    - 課金/消費後にエラーが発生した場合、再課金なしでリトライできるか
      （例: 画像生成でクレジット消費後に生成失敗 → クレジットが戻らず再生成に再課金が必要、は致命的）
    - 楽観的 UI を使っている場合、失敗時に正しくロールバックされるか
    - 課金・削除などの不可逆操作に確認ダイアログがあるか
    - エラー発生時にユーザーが次に何をすべきか明確に案内されているか
    - 処理中（ローディング中）の二重タップ・二重送信が防止されているか
    - 中間状態（処理中断・タイムアウト）でデータやクレジットが失われないか

    【重点】通信断・バックグラウンド遷移での状態保全
    - 処理中に通信が切れた場合の復旧手段があるか
      （例: 画像生成リクエスト送信後に通信断 → 生成結果を後から取得できるか）
    - アプリがバックグラウンドに入った際に進行中の処理が失われないか
      （例: 生成中にホームボタン → 戻ったら結果が消えている）
    - 長時間処理のタイムアウト時にユーザーに明確な案内があるか
      （「エラーが発生しました」だけでなく、リトライ方法や原因を伝える）

    【重点】データ消失防止・境界条件
    - 編集中の未保存データが確認なく破棄されないか
      （例: 長時間かけた編集中に戻るボタン → 確認なしで全消失）
    - カメラ・写真ライブラリ等の権限拒否後に設定画面への導線があるか
    - 空状態（コンテンツゼロ）や上限到達時に適切なガイダンスがあるか
      （例: クレジット 0 で生成ボタンを押せてしまう）

    【標準】UI 品質
    - WCAG 2.2 アクセシビリティ
    - コピーの一貫性（日本語表記ゆれ）
    - NativeWind スタイルの一貫性
    - レイアウトの適切さ

    出力: severity 付きの指摘リスト。
    完了後、TaskUpdate で completed に更新し、チームリーダーに SendMessage で結果を報告すること。
  activeForm: "UI/UX レビュー実行中"
```

**タスク D: レポート集約**（常に作成、他全タスクにブロックされる）

```
TaskCreate:
  subject: "品質レポート集約"
  description: |
    全レビュー結果を集約し、品質レビューレポートを生成する。
    .artifacts/<feature>/REPORT.md に保存。
    reviw-plugin:report-builder エージェントを使用。
  activeForm: "レポート集約中"
```

タスク D は `addBlockedBy` で A, B, C すべてにブロックされるよう設定する。

## Step 3: チームメイト起動

判定結果に基づき、**1つのメッセージ内で同時に** Agent tool でチームメイトを起動する。

> **重要**: チームメイトはリーダーの会話履歴を継承しない。プロジェクトコンテキスト（CLAUDE.md、MCP servers、skills）は自動ロードされるが、タスク固有の情報は spawn プロンプトに含める必要がある。

> **ファイル競合**: レビュー系タスクのため同一ファイル編集の競合リスクは低い。レポート生成のみリーダーが担当する。

### code-reviewer（常に起動）

```
Agent tool:
  name: "code-reviewer"
  subagent_type: "reviw-plugin:review-code-security"
  team_name: "quality-review"
  prompt: |
    あなたは品質レビューチームのコードレビュー担当です。

    プロジェクト: mood-board（AI画像・動画生成モバイルアプリ）
    ベースブランチ: develop
    変更ファイル:
    <変更ファイル一覧をここに展開>

    TaskList でタスクを確認し、「コードレビュー + セキュリティチェック」タスクを
    TaskUpdate で owner を自分に設定して取得してください。

    レビュー完了後:
    1. TaskUpdate で status を completed に更新
    2. チームリーダーに SendMessage で指摘リスト（severity付き）を報告
```

### e2e-tester（HAS_FIREBASE or HAS_MOBILE の場合）

```
Agent tool:
  name: "e2e-tester"
  subagent_type: "reviw-plugin:review-e2e"
  team_name: "quality-review"
  prompt: |
    あなたは品質レビューチームの E2E テスト担当です。

    プロジェクト: mood-board（AI画像・動画生成モバイルアプリ）
    ベースブランチ: develop
    変更ファイル:
    <テスト関連の変更ファイル一覧をここに展開>

    TaskList でタスクを確認し、テスト関連タスクを
    TaskUpdate で owner を自分に設定して取得してください。

    Firebase テストは以下で実行:
    cd mood-board-firebase/functions && npm test

    テスト完了後:
    1. TaskUpdate で status を completed に更新
    2. チームリーダーに SendMessage でテスト結果サマリを報告
```

### ui-reviewer（HAS_UI=true の場合のみ）

```
Agent tool:
  name: "ui-reviewer"
  subagent_type: "reviw-plugin:review-ui-ux"
  team_name: "quality-review"
  prompt: |
    あなたは品質レビューチームの UI/UX レビュー担当です。

    プロジェクト: mood-board（AI画像・動画生成モバイルアプリ、React Native + NativeWind）
    ベースブランチ: develop
    変更ファイル:
    <UI関連の変更ファイル一覧をここに展開>

    TaskList でタスクを確認し、「UI/UX レビュー」タスクを
    TaskUpdate で owner を自分に設定して取得してください。

    レビュー完了後:
    1. TaskUpdate で status を completed に更新
    2. チームリーダーに SendMessage で指摘リスト（severity付き）を報告
```

## Step 4: 結果待機とレポート生成

チームメイトからの完了報告メッセージは自動配信される。ポーリング不要。

> **チームメイトの idle 状態は正常**。メッセージ送信後に idle になるのは通常の動作。SendMessage で復帰できる。

全チームメイトが完了したら：

1. タスク D「品質レポート集約」のブロックが解除される
2. リーダーが各チームメイトの結果を集約
3. `reviw-plugin:report-builder` でレポート生成（利用不可の場合は直接生成）
4. `.artifacts/<feature>/REPORT.md` に保存
5. ターミナルに表示

### レポート形式

```markdown
# 品質レビューレポート

## サマリ
- Code Review: X件の指摘（Critical: X, Warning: X, Info: X）
- E2E Test: X/Y 通過（実行した場合）
- UI/UX: X件の指摘（実行した場合）

## Critical（対応必須）
1. [カテゴリ] 指摘内容

## Warning（対応推奨）
1. [カテゴリ] 指摘内容

## Info（参考情報）
1. [カテゴリ] 指摘内容

## エビデンス
- テスト結果: .artifacts/<feature>/test-results/
- スクリーンショット: .artifacts/<feature>/screenshots/（あれば）
```

## Step 5: チーム解散

レポート提示後、以下の順序でクリーンアップする。**順序が重要**：アクティブなメンバーがいる状態で TeamDelete すると失敗する。

1. 全チームメイトに `SendMessage` でシャットダウンを依頼
2. 全チームメイトの終了を確認（idle 通知が来なくなる）
3. `TeamDelete` でチームリソースを削除

> **注意**: TeamDelete は必ずリーダーが実行する。チームメイトからは実行しない。

## 注意事項

- Agent A（コードレビュー）は常に実行する
- Agent B（テスト）は変更種別に応じて Firebase / Maestro を選択
- Agent C（UI/UX）は UI 変更がある場合のみ実行
- Maestro E2E はユーザー確認後に実行（シミュレータ必要のため）
- チームメイトはプロジェクトコンテキスト（CLAUDE.md 等）を自動ロードするが、リーダーの会話履歴は継承しない
- 1セッションにつき1チームのみ。新しいチームを作る前に現在のチームをクリーンアップすること
- チームメイトはネストされたチームを作成できない
