# Backend Scaffold

Cloud Run 向けの TypeScript / Express backend です。  
chat / voice / image / daily refresh の実配線は `backend/src/index.ts` を基準にしています。

## Endpoints
- `POST /v1/session/initialize`
- `POST /v1/characters`
- `POST /v1/chat/messages`
- `GET/Upgrade /v1/live/voice`
- `POST /v1/chat/voice`
- `POST /v1/characters/image`
- `POST /v1/jobs/daily-refresh`

## Required env vars
- `GOOGLE_CLOUD_PROJECT`
- `VERTEX_LOCATION`
- `LIVE_VERTEX_LOCATION`
- `GEMINI_MODEL`
- `GEMINI_IMAGE_MODEL`
- `LIVE_MODEL_PRIMARY`
- `LIVE_MODEL_FALLBACK`
- `LIVE_SESSION_HANDLE_TTL_SECONDS`
- `GEMINI_TEMPERATURE`
- `GEMINI_MAX_OUTPUT_TOKENS`
- `GEMINI_THINKING_BUDGET`
- `DAILY_SUMMARY_TEMPERATURE`
- `DAILY_SUMMARY_MAX_OUTPUT_TOKENS`
- `DAILY_SUMMARY_THINKING_BUDGET`
- `DAILY_BUBBLE_TEMPERATURE`
- `DAILY_BUBBLE_MAX_OUTPUT_TOKENS`
- `DAILY_BUBBLE_THINKING_BUDGET`
- `IMAGE_BUCKET`
- `SPEECH_LANGUAGE_CODE`
- `TTS_LANGUAGE_CODE`
- `TTS_MODEL_NAME`
- `TTS_AUDIO_ENCODING`
- `SERVICE_ACCOUNT_JSON` or Application Default Credentials
- `DAILY_REFRESH_SECRET`

推奨初期値:
- `VERTEX_LOCATION=global`
- `LIVE_VERTEX_LOCATION=us-central1`
- `GEMINI_MODEL=gemini-2.5-pro`
- `GEMINI_IMAGE_MODEL=gemini-2.5-flash-image`
- `LIVE_MODEL_PRIMARY=gemini-live-2.5-flash-native-audio`
- `LIVE_MODEL_FALLBACK=gemini-live-2.5-flash-native-audio`
- `LIVE_SESSION_HANDLE_TTL_SECONDS=1800`
- `GEMINI_TEMPERATURE=0.7`
- `GEMINI_MAX_OUTPUT_TOKENS=2048`
- `GEMINI_THINKING_BUDGET=128`
- `DAILY_SUMMARY_TEMPERATURE=0.35`
- `DAILY_SUMMARY_MAX_OUTPUT_TOKENS=320`
- `DAILY_SUMMARY_THINKING_BUDGET=128`
- `DAILY_BUBBLE_TEMPERATURE=0.45`
- `DAILY_BUBBLE_MAX_OUTPUT_TOKENS=120`
- `DAILY_BUBBLE_THINKING_BUDGET=32`
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
- `GET/Upgrade /v1/live/voice` は backend が WebSocket relay となって Gemini Live API の stateful session を中継します。
- Live voice は final transcript のみを `chatThreads/{threadId}/messages` に保存し、そのタイミングで当日の daily summary を再生成します。
- session resumption handle は client に返しつつ、Firestore の `chatThreads/{threadId}/liveSessions/{sessionId}` に短期保持します。
- assistant 音声は `PCM 24kHz mono` を逐次返し、client が barge-in 時に再生バッファを破棄します。
- `POST /v1/chat/voice` は Cloud Speech-to-Text で文字起こしし、Gemini 返答を生成し、Cloud Text-to-Speech で返答音声を作ります。
- 音声会話の保存対象は transcript と assistant text です。音声ファイル自体は永続保存しません。
- `POST /v1/characters/image` は Gemini image generation を呼びます。
- `POST /v1/jobs/daily-refresh` は `03:00 JST` 基準で daily summary / daily bubble / 画像更新を行う想定です。
- `dailyBubbles/{dateKey}` は、前日 summary をもとに生成する当日の短い吹き出し文です。
- onboarding では `age / characterGender / appearancePreset` を受け取り、初回 visual prompt に反映します。
- 画像は Cloud Storage の `characters/{uid}/...` 配下へ保存します。
- 画像生成は `visualPromptBase + appearancePreset + age/gender visual hints + visualEvolutionMemo + 今日の summary + scene items + optional note` で組み立てます。
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
  --set-env-vars "GOOGLE_CLOUD_PROJECT=$project,VERTEX_LOCATION=global,LIVE_VERTEX_LOCATION=us-central1,GEMINI_MODEL=gemini-2.5-pro,GEMINI_IMAGE_MODEL=gemini-2.5-flash-image,LIVE_MODEL_PRIMARY=gemini-live-2.5-flash-native-audio,LIVE_MODEL_FALLBACK=gemini-live-2.5-flash-native-audio,LIVE_SESSION_HANDLE_TTL_SECONDS=1800,GEMINI_TEMPERATURE=0.7,GEMINI_MAX_OUTPUT_TOKENS=2048,GEMINI_THINKING_BUDGET=128,DAILY_SUMMARY_TEMPERATURE=0.35,DAILY_SUMMARY_MAX_OUTPUT_TOKENS=320,DAILY_SUMMARY_THINKING_BUDGET=128,DAILY_BUBBLE_TEMPERATURE=0.45,DAILY_BUBBLE_MAX_OUTPUT_TOKENS=120,DAILY_BUBBLE_THINKING_BUDGET=32,IMAGE_BUCKET=$bucket,SPEECH_LANGUAGE_CODE=ja-JP,TTS_LANGUAGE_CODE=ja-JP,TTS_MODEL_NAME=gemini-2.5-flash-tts,TTS_VOICE_NAME=Kore,TTS_AUDIO_ENCODING=MP3" `
  --set-secrets "DAILY_REFRESH_SECRET=DAILY_REFRESH_SECRET:latest"
```

ルール反映:

```powershell
firebase deploy --project gdgoc-2026-mo-kun --only "firestore:rules,storage"
```

Flutter から Cloud Run を使う場合:

```powershell
flutter run --dart-define=BACKEND_BASE_URL=https://mo-kun-api-922529284142.asia-northeast1.run.app
flutter run --dart-define=BACKEND_BASE_URL=https://mo-kun-api-922529284142.asia-northeast1.run.app --dart-define=BACKEND_WS_URL=wss://mo-kun-api-922529284142.asia-northeast1.run.app/v1/live/voice
```

## Required GCP APIs
- `run.googleapis.com`
- `firestore.googleapis.com`
- `storage.googleapis.com`
- `aiplatform.googleapis.com`
- `speech.googleapis.com`
- `texttospeech.googleapis.com`
- `secretmanager.googleapis.com`

## Realtime Voice Acceptance Criteria
- primary model: `gemini-live-2.5-flash-native-audio`
- fallback model: default is the same as primary unless you explicitly set another valid Vertex Live model
- `send_client_content` is seed-only; live turns use `sendRealtimeInput`
- one server event may contain multiple parts and all parts must be processed
- Gemini 3.1 Live preview constraints remain reference-only and are not used in Vertex deployment
- proactive audio / affective dialog are disabled in MVP
- `thinkingConfig` is omitted because Vertex `gemini-live-2.5-flash-native-audio` does not support Thinking

## Cloud Run Notes For Live Voice
- Cloud Run timeout should be raised for long-lived WebSocket sessions
- session affinity is recommended to reduce reconnect churn
- WebSocket connections keep the instance busy while active, so concurrency and min instances should be sized accordingly

## Recommended runtime IAM for the Cloud Run service account
- `roles/aiplatform.user`
- `roles/datastore.user`
- `roles/secretmanager.secretAccessor`
- `roles/storage.objectUser`
- `roles/speech.client`

必要に応じて、bucket 単位の IAM や Secret 単位の IAM でより細かく絞る構成にもできます。
