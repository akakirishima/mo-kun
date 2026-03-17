# デジタル生命体育成アプリケーション「自分育成たまごっち（仮称）」
GDGoC Japan Hackathon 2026 参加プロジェクト  
テーマ: `Brand New "Hello World."`

## Overview
本プロジェクトは、AI キャラクターを介してユーザー自身の自己研鑽を促進するデジタル生命体育成アプリケーションです。  
日々の行動をシステムに報告することで、生成 AI が内容を解析し、会話、日次サマリー、キャラクター画像の変化に反映します。

## Current Product Shape
- `HomeScreen` が現在の本番 chat UI です。`ChatScreen` は旧 UI のため本導線では使っていません。
- `Home` では Gemini 連携済みの chat を利用できます。
- `Diary` では daily summary を表示します。
- `Image` では Gemini で生成したキャラクター画像の最新状態と履歴を表示し、手動再生成できます。
- `Home` 画面中央も、生成済みの最新キャラクター画像を優先表示します。

画面詳細は [`docs/ui/current-ui-prototype.md`](docs/ui/current-ui-prototype.md) を参照してください。

## Tech Stack
- Frontend: Flutter 3.41.2 (stable)
- Backend: TypeScript / Express on Cloud Run
- Data / Auth / Storage: Firebase, Firestore, Cloud Storage
- AI / ML: Vertex AI, Gemini

## AI Integration
- chat model: `gemini-2.5-flash`
- image model: `gemini-2.5-flash-image`
- `VERTEX_LOCATION=global` を前提にしています

画像生成では次の情報を使います。
- `character.visualPromptBase`
- 直近 7 日分の daily summary から圧縮した `visualEvolutionMemo`
- 当日の daily summary
- 手動再生成時の optional note

生成画像は Cloud Storage に保存し、Firestore には最新画像と履歴メタデータを保持します。

## Quick Start
```bash
flutter pub get
flutter doctor -v
flutter devices
flutter run
```

Cloud Run 上の backend を使う場合:

```bash
flutter run --dart-define=BACKEND_BASE_URL=https://<cloud-run-url>
```

詳細なセットアップ手順は [`docs/setup/flutter.md`](docs/setup/flutter.md) を参照してください。  
Git 運用ルールは [`docs/git-rules.md`](docs/git-rules.md) を参照してください。

## Backend / Infra Notes
- backend の実配線は `backend/src/index.ts` が基準です
- AI 連携の中核は `backend/src/services/ai-service.ts` です
- 画像生成、Cloud Storage 保存、Firestore 更新は `backend/src/services/character-image-service.ts` でまとめています
- 手動再生成 API は `POST /v1/characters/image`
- 日次更新 API は `POST /v1/jobs/daily-refresh`
- 日付境界は app / backend ともに `03:00 JST` です

backend の詳細は [`backend/README.md`](backend/README.md) と [`docs/backend/implementation_notes.md`](docs/backend/implementation_notes.md) を参照してください。

## Project Structure
- `lib/main.dart`: アプリ起動エントリポイント
- `lib/app/`: `MaterialApp`、下部ナビ、タブ定義
- `lib/core/`: repository, provider, theme, shared utilities
- `lib/features/`: `home / diary / image / chat / onboarding` ごとの画面実装
- `backend/`: Cloud Run 向け Express サービス
- `docs/backend/`: backend 実装メモとデプロイ補足
- `test/app/`: アプリシェルの widget test
- `test/features/`: 各 feature の widget test

## Verification
最低限の確認ポイント:
- `Home` で Gemini の chat 応答が返る
- `Image` タブから画像を再生成できる
- `Home` 中央に最新生成画像が反映される
- `POST /v1/jobs/daily-refresh` で daily summary と画像更新が動く

## Development Status
- [x] Flutter app の土台整理
- [x] backend MVP foundation
- [x] Gemini chat integration
- [x] Gemini image generation + Cloud Storage persistence
- [x] Home / Diary / Image の backend 接続
- [ ] Cloud Scheduler を含む本番運用の最終整備
- [ ] prompt / UX の継続改善

---
This repository is for the GDGoC Japan Hackathon 2026.
