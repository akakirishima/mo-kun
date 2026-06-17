# Git Rules

ハッカソン期間中の並行開発で、`main` を壊したり、レビューしづらい大きな差分になったりすることを避けるための運用ルールです。

## ブランチ

- `main` へ直接 push しない
- 作業は `main` から新しいブランチを切って始める
- ブランチ名は作業内容が分かる名前にする

例:

- `feat/login-ui`
- `fix/home-scroll`
- `docs/setup-guide`
- `chore/flutter-bootstrap`

## コミット

- 1 コミットはできるだけ 1 つの目的に絞る
- コミットメッセージは短く、内容が分かる形にする
- Issue がある作業は、コミットメッセージの末尾で Issue 番号を紐付ける

推奨 prefix:

- `feat:`
- `fix:`
- `docs:`
- `chore:`
- `refactor:`
- `test:`

例:

- `docs: Git運用ルールを追加 (#1)`
- `feat: 初回オンボーディング画面を追加`
- `fix: ホーム画面のスクロール崩れを修正`

## Pull Request

- 変更は PR ベースで `main` に取り込む
- 1 つの PR は 1 テーマに絞る
- PR には概要、変更内容、確認したことを書く
- UI 変更がある場合はスクリーンショットを付ける

## マージ前チェック

```bash
flutter analyze
flutter test
```

backend を変更した場合:

```bash
cd backend
npm run check
```

## 補足

- 大きめの作業は先に Issue を作ってから着手する
- 迷った場合は、大きな 1 PR より小さな PR に分ける
- 他の人の未反映変更を上書きしない
