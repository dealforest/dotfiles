# Conventional Commits

Git コミット作成時は Conventional Commits 仕様に従う。

## フォーマット

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## タイプ

| Type | 説明 |
|------|------|
| feat | 新機能 |
| fix | バグ修正 |
| docs | ドキュメント変更 |
| style | コードスタイル変更（フォーマット、ロジック変更なし） |
| refactor | リファクタリング（機能追加/修正なし） |
| perf | パフォーマンス改善 |
| test | テストの追加・更新 |
| build | ビルドシステム・依存関係 |
| ci | CI/CD 設定 |
| chore | メンテナンスタスク |

## Scope

scope は任意で、変更の影響範囲を示す。

```
feat(auth): OAuth2 ログインサポートを追加
fix(ui): ボタンの配置問題を解決
refactor(api): エラーハンドリングを簡素化
```

よく使う scope: `auth`, `ui`, `api`, `db`, `config`, `deps`, `core`

**注意:** `claude` のような汎用的なツール名を scope に使用しない。より具体的な機能名（`rules`, `plugins`, `hooks` など）を使用する。

## Body

body は追加のコンテキストを提供。description から空行で区切る。

- **何を**、**なぜ** 変更したかを説明（方法ではなく）
- 複数段落可
- 72文字で折り返し

```
fix: ユーザーセッションの競合状態を防止

初期化完了前にセッションにアクセスしていた。
これによりアプリ起動時に断続的なクラッシュが発生。

スレッドセーフなアクセスのためにミューテックスロックを追加。
```

## Breaking Changes

破壊的変更は互換性のない API 変更を示す。2つの方法がある:

### 1. type/scope の後に `!` を追加

```
feat!: 非推奨の API エンドポイントを削除

feat(api)!: 認証フローを変更
```

### 2. footer に `BREAKING CHANGE:` を追加

```
feat: ユーザー認証をリファクタリング

BREAKING CHANGE: ログインエンドポイントはユーザー名ではなくメールを必要とする。
旧: POST /login { username, password }
新: POST /login { email, password }
```

両方を組み合わせることも可能。`BREAKING-CHANGE`（ハイフン）も有効。

## Footers

footer はメタデータを提供。body から空行で区切る。

| Footer | 説明 |
|--------|------|
| `BREAKING CHANGE:` | 破壊的変更の説明 |
| `Refs #123` | 関連 issue への参照 |
| `Fixes #456` | マージ時に issue をクローズ |
| `Reviewed-by: Name` | コードレビュアー |

```
feat(auth): 二要素認証を追加

セキュリティ強化のため TOTP ベースの 2FA を実装。

Fixes #234
Refs #123
```

## セマンティックバージョニング

Conventional Commits は Semantic Versioning (SemVer) と対応:

| コミットタイプ | バージョンバンプ | 例 |
|---------------|-----------------|-----|
| `fix` | PATCH (0.0.x) | 1.0.0 → 1.0.1 |
| `feat` | MINOR (0.x.0) | 1.0.0 → 1.1.0 |
| `BREAKING CHANGE` | MAJOR (x.0.0) | 1.0.0 → 2.0.0 |

## Revert

以前のコミットを取り消す場合、`revert:` タイプと元のコミットの subject を使用。

```
revert: feat(auth): OAuth2 ログインサポートを追加

コミット abc1234 を取り消し。
理由: OAuth プロバイダーが API を非推奨化。
```

## ルール

1. type は必須で小文字
2. description は命令形（「追加する」ではなく「追加」）
3. description の末尾にピリオドを付けない
4. 1行目は72文字以内
5. 必要に応じて body で詳細を説明

## 例

### シンプル（description のみ）

```
feat: 動画生成機能を追加
fix: アプリ起動時のクラッシュを解決
docs: README にインストール手順を追加
```

### scope 付き

```
feat(video): 2フレームからの生成を追加
fix(auth): 期限切れトークンを適切に処理
```

### body と footer 付き

```
fix(ui): iOS でのスクリーンキャプチャ防止を遅延

usePreventScreenCapture() がネイティブビュー階層の準備前に
呼び出され、起動時に EXC_BAD_ACCESS クラッシュが発生。

- prevention を useEffect に移動
- iOS 用に 500ms の遅延を追加
- エラーハンドリングを追加

Fixes #789
```

### 破壊的変更

```
feat(api)!: 認証レスポンス形式を変更

BREAKING CHANGE: /auth/login エンドポイントは
{ accessToken, refreshToken } の代わりに { token, expiresAt } を返す。

移行: クライアントコードを新しい token フィールドを使用するよう更新。
```
