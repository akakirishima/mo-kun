# raise you

`raise you` は、日々の会話、音声、写真、振り返りをもとに、ユーザー自身を投影した AI キャラクターが変化していく自己育成アプリです。

GDGoC Japan Hackathon 2026 のテーマ `Brand New "Hello World."` に対して、「毎日の記録から立ち上がる新しい自己像に出会う」体験として設計しました。

## プロダクト概要

一般的な習慣化アプリは、タスク達成や数値管理に寄りやすく、記録を続ける心理的な負担が残ります。

`raise you` では、ユーザーの入力を単なるログではなく、内面を映す AI キャラクター、日記、翌朝のひとこと、部屋の小物、画像の雰囲気に変換します。

価値の中心は、AI と別人格の関係を築くことではなく、日々の行動や感情が「自分の変化」として見えることです。

## 体験の流れ

1. 初回に、呼ばれたい名前、頑張りたいこと、接し方、苦手なことを入力する
2. backend がユーザー自身を投影したキャラクター設定と初期ビジュアルを生成する
3. Home からテキスト、音声、写真でその日の出来事を報告する
4. Gemini が会話応答を返し、同時に daily summary を更新する
5. 翌朝、前日の summary をもとに短い bubble を表示する
6. 直近の記録をもとに、キャラクター画像と部屋の小物を更新する
7. Diary で記録がある日だけを振り返る

## 主な機能

- 初回オンボーディングとキャラクター生成
- テキストチャット
- push-to-talk 音声会話
- 写真付きメッセージの軽量解析
- daily summary の自動生成
- 翌朝 bubble の生成
- Gemini image generation によるキャラクター画像更新
- Diary での日次記録閲覧
- Home / Diary / Image / Settings の Flutter UI

## 技術スタック

### App

- Flutter 3.41.x stable
- Riverpod
- Firebase Auth
- Firestore
- Firebase Storage
- WebSocket
- PCM audio streaming

### Backend

- TypeScript
- Express
- Cloud Run
- Vertex AI Gemini
- Gemini Live API
- Cloud Speech-to-Text
- Cloud Text-to-Speech
- Cloud Scheduler
- Secret Manager

### AI / ML

- 会話生成: Gemini
- 日次サマリー生成: Gemini
- 翌朝 bubble 生成: Gemini
- 画像生成: Gemini image generation
- 音声認識: Cloud Speech-to-Text
- 音声返答: Cloud Text-to-Speech / Gemini Live API

## Backend API

- `POST /v1/session/initialize`
- `POST /v1/characters`
- `POST /v1/chat/messages`
- `GET/Upgrade /v1/live/voice`
- `POST /v1/chat/voice`
- `POST /v1/characters/image`
- `POST /v1/jobs/daily-refresh`

## データ設計の要点

- `users/{uid}`: ユーザープロフィールと目標
- `characters/{uid}`: キャラクター設定、画像、visual memo
- `chatThreads/{threadId}/messages`: 会話履歴
- `users/{uid}/dailySummaries/{dateKey}`: 日次サマリー
- `users/{uid}/dailyBubbles/{dateKey}`: 翌朝 bubble
- Storage `characters/{uid}/...`: 生成画像

日付境界は `03:00 JST` に統一し、深夜の行動を前日の延長として扱います。

## セットアップ

Flutter:

```bash
flutter pub get
flutter doctor -v
flutter devices
flutter run
```

Cloud Run 上の backend を使う場合:

```bash
flutter run \
  --dart-define=BACKEND_BASE_URL=https://<cloud-run-service> \
  --dart-define=BACKEND_WS_URL=wss://<cloud-run-service>/v1/live/voice
```

backend:

```bash
cd backend
npm install
npm run check
npm run dev
```

詳細な Flutter セットアップは [docs/setup/flutter.md](docs/setup/flutter.md) を参照してください。

backend の詳細は [backend/README.md](backend/README.md) と [docs/backend/implementation_notes.md](docs/backend/implementation_notes.md) を参照してください。

## 検証

Flutter:

```bash
flutter analyze
flutter test
```

Backend:

```bash
cd backend
npm run check
```

確認する観点:

- Home で最新キャラクター画像と bubble が表示される
- テキストチャットの応答が返り、当日の daily summary が更新される
- push-to-talk で WebSocket live voice に接続できる
- final transcript のみが会話履歴に保存される
- Diary で記録がある日だけを確認できる
- Image タブから画像を再生成できる
- `POST /v1/jobs/daily-refresh` で daily summary / daily bubble / 画像更新が実行できる

## 開発状況

- [x] Flutter app の基本構成
- [x] backend MVP foundation
- [x] Gemini chat integration
- [x] Gemini Live API ベースのリアルタイム音声会話
- [x] daily bubble generation
- [x] Gemini image generation と Storage 永続化
- [x] Home / Diary / Image の backend 接続
- [ ] Cloud Scheduler を含む本番運用の最終調整
- [ ] prompt / UX の継続改善

## 関連メモ

- [Flutter Setup Guide](docs/setup/flutter.md)
- [Backend Implementation Notes](docs/backend/implementation_notes.md)
- [Backend Scaffold](docs/backend/backend_scaffold.md)
- [Backend MVP Plan](docs/backend/backend_mvp_plan.md)
- [Competitive Analysis](docs/competitive-analysis.md)
