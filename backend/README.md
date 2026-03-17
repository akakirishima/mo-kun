# Backend Scaffold

Cloud Run 向けの TypeScript / Express backend です。  
chat / image / daily refresh の実配線は `backend/src/index.ts` を基準にしています。

## Endpoints
- `POST /v1/session/initialize`
- `POST /v1/characters`
- `POST /v1/chat/messages`
- `POST /v1/characters/image`
- `POST /v1/jobs/daily-refresh`

## Required env vars
- `GOOGLE_CLOUD_PROJECT`
- `VERTEX_LOCATION`
- `GEMINI_MODEL`
- `GEMINI_IMAGE_MODEL`
- `GEMINI_TEMPERATURE`
- `GEMINI_MAX_OUTPUT_TOKENS`
- `IMAGE_BUCKET`
- `SERVICE_ACCOUNT_JSON` or Application Default Credentials
- `DAILY_REFRESH_SECRET`

推奨初期値:
- `VERTEX_LOCATION=global`
- `GEMINI_MODEL=gemini-2.5-flash`
- `GEMINI_IMAGE_MODEL=gemini-2.5-flash-image`
- `GEMINI_TEMPERATURE=0.7`
- `GEMINI_MAX_OUTPUT_TOKENS=220`

## Local development
```bash
cd backend
npm install
npm run dev
```

## Notes
- chat は `gemini-2.5-flash`、image は `gemini-2.5-flash-image` を前提にしています。
- `POST /v1/chat/messages` は Gemini chat を返します。
- `POST /v1/characters/image` は Gemini image generation を呼びます。
- `POST /v1/jobs/daily-refresh` は `03:00 JST` 基準で daily summary と画像更新を行う想定です。
- 画像は Cloud Storage の `characters/{uid}/...` 配下へ保存します。
- 画像生成は `visualPromptBase + visualEvolutionMemo + 今日の summary + optional note` で組み立てます。
- `visualEvolutionMemo` は直近 7 日分の daily summary から再構築し、`characters/{uid}` に保存します。
- Firestore 書き込みと Firebase ID token 検証の構造は本番用に分けてあります。

## Deploy
PowerShell:

```powershell
$sa = "mo-kun-backend@<project-id>.iam.gserviceaccount.com"

gcloud run deploy mo-kun-api --source backend --region asia-northeast1 --allow-unauthenticated --service-account $sa --set-env-vars "GOOGLE_CLOUD_PROJECT=<project-id>,VERTEX_LOCATION=global,GEMINI_MODEL=gemini-2.5-flash,GEMINI_IMAGE_MODEL=gemini-2.5-flash-image,GEMINI_TEMPERATURE=0.7,GEMINI_MAX_OUTPUT_TOKENS=220,IMAGE_BUCKET=<storage-bucket-name>" --set-secrets "DAILY_REFRESH_SECRET=DAILY_REFRESH_SECRET:latest"
```

ルール反映:

```powershell
firebase deploy --project <project-id> --only "firestore:rules,storage"
```

