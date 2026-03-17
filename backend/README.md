# Backend Scaffold

Cloud Run 向けの TypeScript / Express 骨組みです。

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
- `IMAGE_MODEL`
- `SERVICE_ACCOUNT_JSON` or Application Default Credentials
- `DAILY_REFRESH_SECRET`

## Local development
```bash
cd backend
npm install
npm run dev
```

## Notes
- 現時点では Vertex / image generation は service 層を差し替えやすい stub 実装です。
- Firestore 書き込みと Firebase ID token 検証の構造は本番用に分けてあります。

