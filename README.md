# デジタル生命体育成アプリケーション「自分育成たまごっち（仮称）」
GDGoC Japan Hackathon 2026 参加プロジェクト  
テーマ: `Brand New "Hello World."`

## Overview
本プロジェクトは、AI キャラクターを介してユーザー自身の自己研鑽を促進するデジタル生命体育成アプリケーションです。  
現在のコンセプトは「相棒と話す」ではなく、`自分を投影したキャラクター / 自分の内なる声` と対話することです。  
日々の行動や会話内容をもとに、生成 AI が返答、日次サマリー、日次吹き出し、キャラクター画像の変化を生成します。

## Current Product Shape
- `HomeScreen` が現在の本番 UI です。会話導線は `Home` に統合しています。
- `Home` では中央のキャラクター画像と、そのキャラクターが話しているように見える日次吹き出しを表示します。
- `Home` の下部アクションは `音声 / 写真 / チャット` です。
- 音声会話は `Flutter <-> Cloud Run(WebSocket) <-> Gemini Live API` の stateful session で動きます。
- マイク音声は `PCM 16kHz mono` を chunk で逐次送信し、assistant 音声も `PCM 24kHz mono` で逐次再生します。
- transcript は final のみを Firestore の会話履歴へ保存します。
- `Diary` では月送りで daily summary を見返せます。表示対象は記録がある日だけです。
- `Image` では Gemini で生成したキャラクター画像の最新状態と履歴を表示し、手動再生成できます。
- `Home` 画面中央も、生成済みの最新キャラクター画像を優先表示します。

## Tech Stack
- Frontend: Flutter 3.41.2 (stable)
- Backend: TypeScript / Express on Cloud Run
- Data / Auth / Storage: Firebase, Firestore, Cloud Storage
- AI / ML: Vertex AI, Gemini Live API, Gemini, Cloud Speech-to-Text, Cloud Text-to-Speech

## AI Integration
- chat model: `gemini-2.5-pro`
- image model: `gemini-2.5-flash-image`
- chat / image は `VERTEX_LOCATION=global` を前提にしています
- live voice は `LIVE_VERTEX_LOCATION=us-central1` など Live API 対応リージョンを使います

Daily summary では次の JSON を Gemini から生成します。
- `title`
- `mood`
- `doneThings`
- `reflection`
- `tomorrowNote`

chat 送信時点で当日 summary を再生成し、`users/{uid}/dailySummaries/{dateKey}` に保存します。  
日次吹き出しは前日 summary をもとに生成し、`users/{uid}/dailyBubbles/{dateKey}` に保存します。  
日付境界は `03:00 JST` です。

画像生成では次の情報を使います。
- `character.visualPromptBase`
- 直近 7 日分の daily summary から圧縮した `visualEvolutionMemo`
- 当日の daily summary
- 当日の summary / 会話から抽出した room scene items
- 手動再生成時の optional note

生成画像は「固定レイアウトの room template + 中央のキャラクター」を基本構図にしています。  
その日の報告内容は、部屋の中の小物として最大 4 件まで prompt に反映します。  
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
flutter run --dart-define=BACKEND_BASE_URL=https://mo-kun-api-922529284142.asia-northeast1.run.app --dart-define=BACKEND_WS_URL=wss://mo-kun-api-922529284142.asia-northeast1.run.app/v1/live/voice
```

詳細なセットアップ手順は [`docs/setup/flutter.md`](docs/setup/flutter.md) を参照してください。  
Git 運用ルールは [`docs/git-rules.md`](docs/git-rules.md) を参照してください。

## Backend / Infra Notes
- backend の実配線は `backend/src/index.ts` が基準です
- AI 連携の中核は `backend/src/services/ai-service.ts` です
- リアルタイム音声 relay は `backend/src/live/` です
- 旧来の音声処理は `backend/src/services/speech-service.ts` に残してありますが、rollback 用です
- 日次吹き出し生成は `backend/src/services/daily-bubble-service.ts` です
- 画像生成、Cloud Storage 保存、Firestore 更新は `backend/src/services/character-image-service.ts` でまとめています
- 手動再生成 API は `POST /v1/characters/image`
- リアルタイム音声 API は `GET/Upgrade /v1/live/voice`
- 旧来の音声会話 API は `POST /v1/chat/voice`
- 日次更新 API は `POST /v1/jobs/daily-refresh`
- Live voice で final transcript が保存されたタイミングでも当日の daily summary を再生成します
- 日付境界は app / backend ともに `03:00 JST` です
- Firestore / Storage rules は `firebase.json` から deploy します

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
- `Home` 上部が固定ヘッダーではなく吹き出し表示になる
- `Home` で Gemini の chat 応答が返る
- `Home` の音声ボタンから Live session に接続できる
- マイク ON 中に partial transcript が進み、final transcript が保存される
- assistant 音声が逐次再生され、ユーザーが話し始めると割り込みできる
- `Home` で送った会話内容が当日の `Diary` に反映される
- `Image` タブから画像を再生成できる
- `Home` 中央に最新生成画像が反映される
- `Diary` が未記録日ではなく、記録がある日だけを表示する
- `POST /v1/jobs/daily-refresh` で daily summary / daily bubble / 画像更新が動く

## Development Status
- [x] Flutter app の土台整理
- [x] backend MVP foundation
- [x] Gemini chat integration
- [x] Gemini Live API ベースのリアルタイム音声会話
- [x] daily bubble generation
- [x] Gemini image generation + Cloud Storage persistence
- [x] Home / Diary / Image の backend 接続
- [ ] Cloud Scheduler を含む本番運用の最終整備
- [ ] prompt / UX の継続改善

## Realtime Voice Acceptance Criteria
- Vertex AI 実運用の primary model は `gemini-live-2.5-flash-native-audio`
- fallback は既定では primary と同一。別モデルを使うなら有効な Vertex Live model を明示する
- `send_client_content` は初回 seed context のみに使い、会話中の音声は `sendRealtimeInput` のみを使う
- 1 server event に複数 part が含まれてもすべて処理する
- Gemini 3.1 Live preview 制約は参考情報に留め、Vertex 配備では採用しない
- proactive audio / affective dialog は初期実装で無効
- Vertex の `gemini-live-2.5-flash-native-audio` では Thinking 非対応のため `thinkingConfig` は送らない

---
This repository is for the GDGoC Japan Hackathon 2026.
