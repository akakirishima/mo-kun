# デジタル生命体育成アプリケーション「自分育成たまごっち（仮称）」
GDGoC Japan Hackathon 2026 参加プロジェクト  
テーマ: `Brand New "Hello World."`

## Overview
本プロジェクトは、AI キャラクターを介してユーザー自身の自己研鑽を促進するデジタル生命体育成アプリケーションです。  
日々の行動をシステムに報告することで、生成 AI が内容を解析し、内部パラメータの増減とキャラクターの変化に反映します。

## Current UI Prototype
現在の UI プロトタイプは、アプリ全体の土台共有を目的に `Home / chat / diary / image` の 4 タブ構成で整理しています。

- `Home`: ピンク基調の「今日の一言 + キャラ部屋 + 話しかける」。今日の一言は Mori の文字起こしエリア
- `chat`: LINE風の 1 対 1 会話画面。上部に検索と Home 通話導線、下部にカメラ / 画像 / メッセージ / マイク / 電話
- `diary`: 1日のまとめを見る日記画面。気分、できたこと、振り返り、明日のひとことを配置
- `image`: ストーリー風ハイライト、AI Select グリッド、右下の投稿 FAB を持つギャラリー画面

画面詳細、ファイル構成、未実装項目、次の一手は [`docs/ui/current-ui-prototype.md`](docs/ui/current-ui-prototype.md) を参照してください。

## Tech Stack
- Frontend: Flutter 3.41.2 (stable)
- Backend / Infrastructure: Google Cloud / Firebase
- AI / ML: Gemini API, Vertex AI

## Quick Start
```bash
flutter pub get
flutter doctor -v
flutter devices
flutter run
```

詳細なセットアップ手順は [`docs/setup/flutter.md`](docs/setup/flutter.md) を参照してください。  
Git 運用ルールは [`docs/git-rules.md`](docs/git-rules.md) を参照してください。

## Project Structure
- `lib/main.dart`: アプリ起動エントリポイント
- `lib/app/`: `MaterialApp`、下部ナビ、タブ定義
- `lib/core/`: テーマと共有 UI コンポーネント
- `lib/features/`: `home / chat / diary / image` ごとの画面実装
- `test/app/`: アプリシェルの widget test
- `test/features/`: 各 feature の widget test
- `docs/ui/current-ui-prototype.md`: 現状 UI 共有用ドキュメント

## Development Status
- [x] リポジトリの初期化
- [x] Flutter 環境構築
- [x] UI プロトタイプの土台整理
- [ ] Gemini / Vertex AI のプロンプトエンジニアリングと検証
- [ ] フロントエンド / バックエンドの実装

---
This repository is for the GDGoC Japan Hackathon 2026.
