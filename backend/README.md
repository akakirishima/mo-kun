# Backend

`raise you` の Cloud Run 向け TypeScript / Express backend です。

Flutter app からのチャット、音声、画像生成、日次更新を受け、Firebase と Vertex AI 系サービスへ接続します。

## 役割

- 初回セッションとキャラクター生成
- テキストチャット応答
- push-to-talk 音声会話
- Gemini Live API の WebSocket relay
- daily summary と daily bubble の生成
- Gemini image generation と Cloud Storage 保存
- Cloud Scheduler から呼び出す日次更新 job

## 主な endpoint

- `POST /v1/session/initialize`
- `POST /v1/characters`
- `POST /v1/chat/messages`
- `GET/Upgrade /v1/live/voice`
- `POST /v1/chat/voice`
- `POST /v1/characters/image`
- `POST /v1/jobs/daily-refresh`

## セットアップ

```bash
npm install
npm run check
npm run dev
```

## 環境変数

### Google Cloud / Firebase

- `GOOGLE_CLOUD_PROJECT`
- `VERTEX_LOCATION`
- `LIVE_VERTEX_LOCATION`
- `IMAGE_BUCKET`
- `SERVICE_ACCOUNT_JSON` または ADC
- `DAILY_REFRESH_SECRET`

### Gemini

- `GEMINI_MODEL`
- `GEMINI_IMAGE_MODEL`
- `GEMINI_TEMPERATURE`
- `GEMINI_MAX_OUTPUT_TOKENS`
- `GEMINI_THINKING_BUDGET`

### Daily summary / bubble

- `DAILY_SUMMARY_TEMPERATURE`
- `DAILY_SUMMARY_MAX_OUTPUT_TOKENS`
- `DAILY_SUMMARY_THINKING_BUDGET`
- `DAILY_BUBBLE_TEMPERATURE`
- `DAILY_BUBBLE_MAX_OUTPUT_TOKENS`
- `DAILY_BUBBLE_THINKING_BUDGET`

### Live voice / speech

- `LIVE_MODEL_PRIMARY`
- `LIVE_MODEL_FALLBACK`
- `LIVE_SESSION_HANDLE_TTL_SECONDS`
- `SPEECH_LANGUAGE_CODE`
- `TTS_LANGUAGE_CODE`
- `TTS_MODEL_NAME`
- `TTS_VOICE_NAME`
- `TTS_AUDIO_ENCODING`

## 推奨初期値の考え方

- 通常の chat / image は `VERTEX_LOCATION=global` を基本にする
- Gemini Live API は対応リージョンを `LIVE_VERTEX_LOCATION` に指定する
- `LIVE_MODEL_PRIMARY` と `LIVE_MODEL_FALLBACK` は、どちらも有効な Vertex Live model にする
- `IMAGE_BUCKET` は Firebase Storage bucket 名を `gs://` なしで指定する
- `DAILY_REFRESH_SECRET` は Cloud Scheduler からの日次 job 呼び出し検証に使う

## デプロイ

Cloud Run へ deploy する場合は、実プロジェクト名や bucket 名を README に固定せず、環境ごとに値を注入します。

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

Firestore / Storage rules は Firebase CLI から反映します。

```bash
firebase deploy --project <project-id> --only "firestore:rules,storage"
```

## Runtime IAM

Cloud Run の service account には、実行に必要な権限だけを付与します。

- `roles/aiplatform.user`
- `roles/datastore.user`
- `roles/secretmanager.secretAccessor`
- `roles/storage.objectUser`
- `roles/speech.client`

## 検証

```bash
npm run check
```

確認する観点:

- `POST /v1/chat/messages` が Gemini 応答と daily summary 更新を行う
- `GET/Upgrade /v1/live/voice` が WebSocket relay として接続できる
- final transcript のみが Firestore に保存される
- `POST /v1/characters/image` が画像生成、Storage 保存、Firestore 更新を行う
- `POST /v1/jobs/daily-refresh` が `03:00 JST` 基準で日次処理を実行する

## 運用メモ

- WebSocket は接続中に Cloud Run instance を占有するため、timeout、concurrency、min instances を実利用に合わせて調整する
- 音声会話の音声ファイル自体は永続保存せず、transcript と assistant text を保存する
- 日付境界は app / backend ともに `03:00 JST` でそろえる
