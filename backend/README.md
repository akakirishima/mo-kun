# Backend Scaffold

Cloud Run 向けの TypeScript / Express backend です。  
chat / voice / image / daily refresh の実配線は `backend/src/index.ts` を基準にしています。

## Endpoints
- `POST /v1/session/initialize`
- `POST /v1/characters`
- `POST /v1/chat/messages`
- `POST /v1/chat/voice`
- `POST /v1/characters/image`
- `POST /v1/jobs/daily-refresh`

## Required env vars
- `GOOGLE_CLOUD_PROJECT`
- `VERTEX_LOCATION`
- `GEMINI_MODEL`
- `GEMINI_IMAGE_MODEL`
- `GEMINI_TEMPERATURE`
- `GEMINI_MAX_OUTPUT_TOKENS`
- `GEMINI_THINKING_BUDGET`
- `IMAGE_BUCKET`
- `SPEECH_LANGUAGE_CODE`
- `TTS_LANGUAGE_CODE`
- `TTS_MODEL_NAME`
- `TTS_AUDIO_ENCODING`
- `SERVICE_ACCOUNT_JSON` or Application Default Credentials
- `DAILY_REFRESH_SECRET`

推奨初期値:
- `VERTEX_LOCATION=global`
- `GEMINI_MODEL=gemini-2.5-pro`
- `GEMINI_IMAGE_MODEL=gemini-2.5-flash-image`
- `GEMINI_TEMPERATURE=0.7`
- `GEMINI_MAX_OUTPUT_TOKENS=2048`
- `GEMINI_THINKING_BUDGET=128`
- `SPEECH_LANGUAGE_CODE=ja-JP`
- `TTS_LANGUAGE_CODE=ja-JP`
- `TTS_MODEL_NAME=gemini-2.5-flash-tts`
- `TTS_AUDIO_ENCODING=MP3`

`IMAGE_BUCKET` は Firebase Storage bucket 名を `gs://` なしで指定します。  
`TTS_VOICE_NAME` は未指定なら `Kore` を使います。  
`TTS_PROMPT` は未指定なら落ち着いた内なる声向けの prompt を使います。

## Local development
```bash
cd backend
npm install
npm run check
npm run dev
```

## Notes
- chat は `gemini-2.5-pro`、image は `gemini-2.5-flash-image` を前提にしています。
- `POST /v1/chat/messages` は Gemini chat を返し、その時点で当日の daily summary を再生成します。
- `POST /v1/chat/voice` は Cloud Speech-to-Text で文字起こしし、Gemini 返答を生成し、Cloud Text-to-Speech で返答音声を作ります。
- 音声会話の保存対象は transcript と assistant text です。音声ファイル自体は永続保存しません。
- `POST /v1/characters/image` は Gemini image generation を呼びます。
- `POST /v1/jobs/daily-refresh` は `03:00 JST` 基準で daily summary / daily bubble / 画像更新を行う想定です。
- `dailyBubbles/{dateKey}` は、前日 summary をもとに生成する当日の短い吹き出し文です。
- 画像は Cloud Storage の `characters/{uid}/...` 配下へ保存します。
- 画像生成は `visualPromptBase + visualEvolutionMemo + 今日の summary + scene items + optional note` で組み立てます。
- scene items は当日の summary / user message から抽出した、部屋の中に置ける具体物です。
- `visualEvolutionMemo` は直近 7 日分の daily summary から再構築し、`characters/{uid}` に保存します。
- `dailySummaries/{dateKey}`、`dailyBubbles/{dateKey}`、`imageHistory.dateKey` はどれも `03:00 JST` cutover で揃えています。

## Deploy
PowerShell:

```powershell
$project = "gdgoc-2026-mo-kun"
$region  = "asia-northeast1"
$service = "mo-kun-api"
$sa      = "mo-kun-backend@$project.iam.gserviceaccount.com"
$bucket  = "gdgoc-2026-mo-kun.firebasestorage.app"

gcloud run deploy $service `
  --project $project `
  --source backend `
  --region $region `
  --allow-unauthenticated `
  --service-account $sa `
  --set-env-vars "GOOGLE_CLOUD_PROJECT=$project,VERTEX_LOCATION=global,GEMINI_MODEL=gemini-2.5-pro,GEMINI_IMAGE_MODEL=gemini-2.5-flash-image,GEMINI_TEMPERATURE=0.7,GEMINI_MAX_OUTPUT_TOKENS=2048,GEMINI_THINKING_BUDGET=128,IMAGE_BUCKET=$bucket,SPEECH_LANGUAGE_CODE=ja-JP,TTS_LANGUAGE_CODE=ja-JP,TTS_MODEL_NAME=gemini-2.5-flash-tts,TTS_VOICE_NAME=Kore,TTS_AUDIO_ENCODING=MP3" `
  --set-secrets "DAILY_REFRESH_SECRET=DAILY_REFRESH_SECRET:latest"
```

ルール反映:

```powershell
firebase deploy --project gdgoc-2026-mo-kun --only "firestore:rules,storage"
```

Flutter から Cloud Run を使う場合:

```powershell
flutter run --dart-define=BACKEND_BASE_URL=https://mo-kun-api-922529284142.asia-northeast1.run.app
```

## Required GCP APIs
- `run.googleapis.com`
- `firestore.googleapis.com`
- `storage.googleapis.com`
- `aiplatform.googleapis.com`
- `speech.googleapis.com`
- `texttospeech.googleapis.com`
- `secretmanager.googleapis.com`

## Recommended runtime IAM for the Cloud Run service account
- `roles/aiplatform.user`
- `roles/datastore.user`
- `roles/secretmanager.secretAccessor`
- `roles/storage.objectUser`
- `roles/speech.client`

必要に応じて、bucket 単位の IAM や Secret 単位の IAM でより細かく絞る構成にもできます。
