---
description: mood-board プロジェクトの Maestro E2E テストを実行する
---

mood-board アプリの Maestro E2E テストをローカル iOS Simulator で実行する。
環境の生存確認・修正・再実行ループを主体とし、フロー YAML 自体は改変しない。

## 実行フロー全体像

```
シミュレータ確認 → Firebase Emulator ready 確認 → アプリビルド判定 → Metro 起動 →
アプリ起動 + ダイアログ処理 → フロー単位実行（FAIL 時: 画面確認 → 修正 → 再実行）→ 結果サマリ
```

## 不変条件（絶対に守る）

- **`mood-board-app/.maestro/flows/*.yaml` の検証ステップ（assertVisible / tapOn / extendedWaitUntil 構成）は改変しない**。これは合意済みの検証仕様。
- 修正してよいレイヤーは以下のみ:
  - `mood-board-app/.maestro/helpers/_prelude.yaml`
  - `mood-board-app/.maestro/helpers/sign_up.yaml`
  - `mood-board-app/.maestro/helpers/sign_out.yaml`
  - 環境: Firebase Emulator (シード再投入、Auth クリア)、Metro 再起動、iOS Simulator keychain / 写真ライブラリ
  - アプリ側コード: `RemoteConfigContext` の初期値、`emulatorConfig.ts` のログ、`SeedTestData` の冪等化など「動作の土台」に相当する小さな修正
- 検証仕様を変えないと通らないと判断した場合（分類 H / I 参照）は、**勝手にフローを書き換えず停止してユーザーに相談する**

## Step 1: シミュレータ確認・起動

### シミュレータ名の取得

`finding-ios-simulator` スキルを使用してシミュレータ名を取得する。

### 起動状態の確認

```bash
xcrun simctl list devices booted 2>/dev/null
```

- 対象シミュレータが起動済み → Step 1.5 へ
- 未起動 → 起動してから Step 1.5 へ

```bash
xcrun simctl boot "$ARGUMENTS" 2>&1 || true
```

## Step 1.5: Firebase Emulator ready 確認（必須）

Firebase Emulator は Maestro フロー（特に 04/05 の生成系）の前提。ここで必ず疎通確認する。

### ポート疎通チェック

```bash
curl -sf http://127.0.0.1:5001/moodboard-genai-dev/asia-northeast1/ >/dev/null 2>&1
```

または:

```bash
lsof -ti:5001 2>/dev/null
```

### 未起動なら起動する

**重要**: グローバル `firebase` コマンドが無い環境があるので、必ず **`functions/node_modules/.bin/firebase`** をフルパスで使う。

Bash の `run_in_background` で起動する:

```bash
cd mood-board-firebase && ./functions/node_modules/.bin/firebase emulators:start \
  --only auth,firestore,functions,storage \
  --project moodboard-genai-dev \
  > /Users/<user>/.../mood-board-app/.artifacts/<feature>/logs/emulator.log 2>&1
```

- ログは必ず絶対パスで出力すること（サブシェルの cwd に依存しない）
- 起動後、5001 ポートが reachable になるまで最大 180 秒待機
- **起動後はセッション終了まで明示的に止めない**（trap や pkill の対象に含めない）

### シード投入と Auth クリア

```bash
curl -sf -X POST "http://127.0.0.1:5001/moodboard-genai-dev/asia-northeast1/onRequest-SeedTestData?reset=1"
curl -sf -X DELETE "http://127.0.0.1:9099/emulator/v1/projects/moodboard-genai-dev/accounts"
```

## Step 2: アプリビルド判定

### Metro/Expo プロセスの確認

```bash
pgrep -f 'expo|metro' 2>/dev/null
```

### 判定ロジック

| 状態 | アクション |
|------|----------|
| このセッションで起動した Metro が生存 | ビルドスキップ → Step 3 |
| 不明な Metro が動作中 | ユーザーに確認 |
| Metro なし + アプリ未インストール | フルビルド（Step 2a） |
| Metro なし + アプリインストール済み | Metro だけ起動 → Step 3 |

### アプリのインストール確認

```bash
xcrun simctl listapps booted 2>/dev/null | grep "dev.mooz.ai.app"
# または
xcrun simctl get_app_container booted dev.mooz.ai.app app 2>/dev/null
```

### Step 2a: フルビルド

```bash
pkill -f 'expo start|metro' 2>/dev/null || true
cd mood-board-app && BUILD_FLAVOR=dev npx expo prebuild --platform ios
cd mood-board-app && BUILD_FLAVOR=dev npx expo run:ios --device "$ARGUMENTS"
```

ビルドは 5〜10 分。`run_in_background` で実行し、完了まで待機。

## Step 3: Metro 起動 + アプリ起動 + ダイアログ処理

### Metro 起動（バックグラウンド）

```bash
cd mood-board-app && FIREBASE_EMULATOR=true BUILD_FLAVOR=dev \
  npx expo start --dev-client -c \
  > /Users/<user>/.../mood-board-app/.artifacts/<feature>/logs/metro.log 2>&1
```

8081 ポートが ready になるまで待機。

### アプリ起動時のダイアログ処理

`expo run:ios` 初回、あるいは `launchApp` 後に出るシステムダイアログを `mcp__maestro__inspect_view_hierarchy` で検出して対処:

| ダイアログ | アクション |
|-----------|----------|
| "Open in mooz.ai?" | 「Open」をタップ |
| 通知許可 | 「Don't Allow」をタップ（フロー側で消費されない想定） |
| トラッキング許可 (ATT) | 「Allow」をタップ |
| Apple Account / "Sign in to Apple Account" | 「Cancel」をタップ |
| Expo Dev Launcher "Development servers" | `dev.mooz.ai` をタップ |

これらは本来 `helpers/_prelude.yaml` が処理する。処理漏れを見つけたら `_prelude.yaml` に追記する（後述のループ内修正）。

## Step 4: アプリ初回起動待機

`take_screenshot` でバンドル完了（SignUp 画面が見えている）を確認する。通常 10〜20 秒。

## Step 5: 録画開始

```bash
mkdir -p .artifacts/<feature>/recordings
xcrun simctl io booted recordVideo --codec h264 \
  .artifacts/<feature>/recordings/session-$(date +%Y%m%d-%H%M%S).mp4 &
RECORD_PID=$!
```

録画は Step 7 で停止する。フロー単位で分けたい場合は各フローの開始／終了で再録画する。

## Step 6: Maestro フローを 1 本ずつ実行（改善ループ込み）

フローは以下の順で、**1 本ずつ**実行する。一括 (`run_flow_files` に複数パスを渡す) は禁止。

```
mood-board-app/.maestro/flows/01_auth.yaml
mood-board-app/.maestro/flows/02_navigation.yaml
mood-board-app/.maestro/flows/03_sign_out_cycle.yaml
mood-board-app/.maestro/flows/04_album_generation.yaml
mood-board-app/.maestro/flows/05_video_generation.yaml
```

### 1 本あたりの実行手順

```
[A] 実行
    mcp__maestro__run_flow_files(device_id=<id>, flow_files="<1本だけ>")

    ↓ PASS → [G] 次のフローへ
    ↓ FAIL

[B] 画面状態の捕捉（必須・最初に 1 回）
    1. mcp__maestro__take_screenshot
       → .artifacts/<feature>/screenshots/<flow>-fail-<timestamp>.png に保存
    2. mcp__maestro__inspect_view_hierarchy
       → 階層 JSON をログへ
    3. tail -80 .artifacts/<feature>/logs/metro.log
    4. tail -80 .artifacts/<feature>/logs/emulator.log

[C] 原因分類（下表）

[D] 分類 A〜G のみ自動修正
    - flows/*.yaml は絶対に触らない
    - 直すのは helpers/*.yaml と環境側のみ
    - 修正内容を REPORT.md の「修正ログ」に追記

[E] 同じフローを再実行
    → PASS: [G] へ
    → 同じエラーで FAIL: [B]〜[D] のループ（最大 3 回）
    → 4 回目に入る前、または分類 H/I に該当: 停止してユーザーに相談

[F] 分類 H / I に突き当たった場合:
    - H: 期待する testID が画面に存在しない（フロー側の検証仕様変更が必要）
    - I: 生成が 5 分超で返ってこない（Emulator の stub/Vertex 設定調査が必要）
    これらは **勝手に flows/*.yaml を書き換えず**、ここで停止してユーザーに報告する

[G] 次のフローへ進む
```

### 原因分類表（Step 6 で FAIL 時に必ず参照）

| 分類 | 典型的な症状                                          | 修正先                                       | 自動/手動 |
|------|-------------------------------------------------------|----------------------------------------------|-----------|
| A    | Expo Dev Launcher が表示されたまま                    | `helpers/_prelude.yaml` に Launcher 処理追加 | 自動      |
| B    | 未処理ダイアログ（Apple/ATT/通知/RedBox）             | `helpers/_prelude.yaml` or `sign_up.yaml`    | 自動      |
| C    | 画面遷移は正しいが要素が描画される前にタップしている  | 該当 helper に `extendedWaitUntil` 追加      | 自動      |
| D    | topic-list-screen が空（データ未シード）              | 環境: `SeedTestData?reset=1` 再実行          | 自動      |
| E    | SignUp 画面のまま匿名ボタンが効かない                 | 環境: Auth Emulator `DELETE accounts`        | 自動      |
| F    | Metro に繋がっていない（白画面・Bundling のまま）     | 環境: Metro 再起動                            | 自動      |
| G    | 前回セッションの keychain / 写真ライブラリが残留       | 環境: `xcrun simctl keychain booted reset` 等| 自動      |
| H    | 期待する testID が画面に存在しない                    | **フロー検証仕様の変更が必要 → 停止相談**    | 手動      |
| I    | 生成が 5 分超で返ってこない                           | **Emulator の生成 stub 調査 → 停止相談**     | 手動      |

## Step 7: 録画停止と保存

```bash
kill -INT $RECORD_PID 2>/dev/null
wait $RECORD_PID 2>/dev/null
```

録画は PASS/FAIL 問わず `.artifacts/<feature>/recordings/` に残す。

## Step 8: 結果サマリ

### 実行情報

```
## 実行情報
- デバイス: iPhone 17 Pro (iOS 26.1)
- Firebase Emulator: ready (PID / ログパス)
- Metro: ready (8081)
- 実行時間: XX 秒
- 録画: .artifacts/<feature>/recordings/xxx.mp4
```

### テスト結果

```
| フロー                         | 結果      | リトライ回数 | 修正内容                        |
|--------------------------------|-----------|-------------|---------------------------------|
| 01_auth.yaml                   | PASS/FAIL | 0/1/2/3     | 例: _prelude に Allow ダイアログ |
| 02_navigation.yaml             |           |             |                                 |
| 03_sign_out_cycle.yaml         |           |             |                                 |
| 04_album_generation.yaml       |           |             |                                 |
| 05_video_generation.yaml       |           |             |                                 |
```

**修正ログ**セクションに、ループ内で何をなぜ直したかを箇条書きで記録する（次回セッションのデバッグ資産になる）。

### エラー時の追加情報

- FAIL したフローのエラーメッセージ
- スクリーンショット・録画・ログへのパス
- 分類（A〜I のどれだったか）

## 画面確認の原則（守るべき姿勢）

1. **FAIL したら画面を見ずに再実行しない**。必ず `take_screenshot` を最初に呼ぶ
2. スクリーンショットで判断できない時は `inspect_view_hierarchy` を併用する
3. 原因が特定できるまで修正を行わない。勘で timeout だけ伸ばすのは禁止
4. 同じエラーで 2 回連続失敗したら、helper / `_prelude.yaml` 側の構造的な欠落を疑う
5. **`flows/*.yaml` の検証ステップは改変禁止**。フロー側を触りたくなった時点で、それは分類 H / I → 停止してユーザーに相談

## デバイス ID の取得

```
mcp__maestro__list_devices()
```

`connected: true` のデバイスを使用。

## プロジェクト固有情報

- **App ID**: `dev.mooz.ai.app`
- **作業ディレクトリ**: `mood-board-app/`
- **フローディレクトリ**: `mood-board-app/.maestro/flows/`
- **Helpers ディレクトリ**: `mood-board-app/.maestro/helpers/`（修正 OK）
- **BUILD_FLAVOR**: `dev`
- **Firebase Emulator**: project=`moodboard-genai-dev`, functions=5001, auth=9099, firestore=8080, storage=9199
- **エビデンス保存先**: `mood-board-app/.artifacts/<feature>/{screenshots,recordings,logs}`（`<feature>` はブランチ名ベース）
