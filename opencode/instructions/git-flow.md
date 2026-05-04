# Git Flow ブランチ戦略

Git Flow に基づいたブランチ戦略に従う。

## メインブランチ

| ブランチ | 役割 | ライフサイクル |
|---------|------|---------------|
| `main` or `master` | 本番環境のコード。常にリリース可能な状態 | 永続 |
| `develop` | 開発の統合ブランチ。次回リリースの最新状態 | 永続 |

## サポートブランチ

| ブランチ | 命名規則 | 分岐元 | マージ先 | 役割 |
|---------|---------|--------|---------|------|
| feature | `feature/<name>` | develop | develop | 新機能開発 |
| release | `release/<version>` | develop | main/master, develop | リリース準備 |
| hotfix | `hotfix/<name>` | main/master | main/master, develop | 緊急バグ修正 |

## ルール

### main/master ブランチ

- 直接コミット禁止
- release または hotfix ブランチからのみマージ
- マージ時にタグを付与 (例: `v1.0.0`)

### develop ブランチ

- 直接コミット禁止 (小さな修正は例外)
- feature, release, hotfix ブランチからマージ

### feature ブランチ

- develop から分岐
- develop にのみマージ
- main/master には直接マージしない
- マージ後は削除

```bash
# 作成
git checkout -b feature/new-feature develop

# マージ
git checkout develop
git merge --no-ff feature/new-feature
git branch -d feature/new-feature
```

### release ブランチ

- develop から分岐 (リリース準備開始時)
- バグ修正、ドキュメント更新のみ許可
- 新機能の追加は禁止
- main/master と develop 両方にマージ
- マージ後は削除

```bash
# 作成
git checkout -b release/1.0.0 develop

# main/master にマージ
git checkout main
git merge --no-ff release/1.0.0
git tag -a v1.0.0

# develop にマージ
git checkout develop
git merge --no-ff release/1.0.0
git branch -d release/1.0.0
```

### hotfix ブランチ

- main/master から分岐 (緊急時のみ)
- main/master と develop 両方にマージ
- マージ後は削除

```bash
# 作成
git checkout -b hotfix/critical-bug main

# main/master にマージ
git checkout main
git merge --no-ff hotfix/critical-bug
git tag -a v1.0.1

# develop にマージ
git checkout develop
git merge --no-ff hotfix/critical-bug
git branch -d hotfix/critical-bug
```

## 命名規則

- feature: `feature/<issue-number>-<short-description>` または `feature/<short-description>`
- release: `release/<version>` (例: `release/1.0.0`)
- hotfix: `hotfix/<issue-number>-<short-description>` または `hotfix/<short-description>`
