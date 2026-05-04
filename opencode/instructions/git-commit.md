# Git コミット

## 原則

小さいコミットを後からくっつけたり並べ替えたりする方が、大きいコミットを後から分割するよりもずっと簡単。迷ったら細かくコミットして後から見直せるようにする。

## 言語

コミットメッセージは日本語で書く。

## ルール

1. **Conventional Commits の種類を混ぜない** - feat と fix など異なるタイプは必ず別コミット

2. **機能・内容を最小単位に** - 1つのコミットは1つの機能や変更内容のみ
   - 悪い例: `feat(claude): sandbox 設定と deny パターンを強化`
   - 良い例:
     - `feat(claude): sandbox 設定を追加`
     - `feat(claude): deny パターンを強化`

3. **ファイル単位ではなく意味単位で分割** - 同じファイルでも独立した変更は別コミット
   - 例: tmux.conf に「URL を開く機能」と「ペイン操作」の変更がある場合は分割

4. **コミット前に差分を確認** - `git diff` で変更内容を確認し、複数の意味が混在していないかチェック

## なぜ細かく分けるのか

- スカッシュは簡単 (`git rebase -i` で squash)
- 並び替えは簡単 (`git rebase -i` で reorder)
- チェリーピックが容易
- 特定の変更だけ取り消せる
- **大きなコミットの分割は難しい**

## 例

### 良い例

```
feat(claude): sandbox 設定を追加
feat(claude): deny パターンに SSH 鍵のフルパス対応を追加
feat(claude): deny パターンに pem/credential/secret を追加
feat(tmux): fzf で URL を選択して開く機能を追加
feat(fish): claude の abbr に --sandbox を追加
```

### 悪い例

```
feat(claude): sandbox 設定と deny パターンを強化
feat: tmux と fish の設定を更新
```

## fixup / squash（指定された場合）

fixup や squash を指定された場合は以下に従う。

### コミット作成

```bash
# メッセージを破棄してコードのみマージ
git commit --fixup <対象コミット>

# メッセージも含めてマージ（エディタが開く）
git commit --squash <対象コミット>
```

### squash 実行

```bash
GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash <親コミット>
```

- 指定するのは「まとめたいコミット」ではなく「その一つ前の親コミット」
- 例: 直近3コミットをまとめる場合は `HEAD~3` を指定

### fixup 先コミットの選び方

- 変更対象のファイルを「最初に作成・変更した」コミットに fixup する
- コミットメッセージではなく、変更内容の論理的な関連性で判断

### 注意事項

- **リモートにプッシュ済みのコミットは fixup/squash しない**（force push が必要になる）
- コンフリクト発生時は解消後 `git rebase --continue`
