# Backend Scaffold

このメモは、`raise you` backend の構成とデプロイ時に確認する項目をまとめたものです。

## 構成

- `backend/src/index.ts`: Express app と route の入口
- `backend/src/services/ai-service.ts`: Gemini chat / summary 系の中心
- `backend/src/live/`: Gemini Live API の WebSocket relay
- `backend/src/services/daily-bubble-service.ts`: 翌朝 bubble 生成
- `backend/src/services/character-image-service.ts`: 画像生成、Storage 保存、Firestore 更新
- `backend/src/services/speech-service.ts`: legacy voice endpoint 用の STT / TTS 処理

## 必要な外部サービス

- Firebase Authentication
- Firestore
- Cloud Storage
- Cloud Run
- Vertex AI
- Gemini Live API
- Cloud Speech-to-Text
- Cloud Text-to-Speech
- Secret Manager
- Cloud Scheduler

## ローカル確認

```bash
cd backend
npm install
npm run check
npm run dev
```

Flutter app から接続する場合は、`BACKEND_BASE_URL` と `BACKEND_WS_URL` を `--dart-define` で渡します。

## Cloud Run デプロイの考え方

README に実プロジェクト ID や bucket 名を固定せず、環境ごとの値を CI/CD または手元の deploy コマンドから渡します。

```bash
gcloud run deploy <service-name> \
  --project <project-id> \
  --source backend \
  --region <region> \
  --allow-unauthenticated \
  --service-account <service-account> \
  --set-env-vars "GOOGLE_CLOUD_PROJECT=<project-id>,VERTEX_LOCATION=global,LIVE_VERTEX_LOCATION=<live-region>,IMAGE_BUCKET=<bucket-name>" \
  --set-secrets "DAILY_REFRESH_SECRET=DAILY_REFRESH_SECRET:latest"
```

## デプロイ後チェック

- `/v1/session/initialize` が Firebase user 前提で動く
- `/v1/chat/messages` が Gemini 応答を返す
- `/v1/live/voice` が WebSocket upgrade を受けられる
- `/v1/characters/image` が Storage と Firestore を更新する
- `/v1/jobs/daily-refresh` が secret 検証つきで呼べる
- Firestore / Storage rules が対象 project に反映されている

## 運用上の注意

- Live voice は長時間接続になるため、Cloud Run timeout と concurrency を明示的に調整する
- Cloud Scheduler からの job 呼び出しには共有 secret を使う
- service account には必要最小限の IAM を付与する
- 本番値は README ではなく secret manager や環境変数で管理する
