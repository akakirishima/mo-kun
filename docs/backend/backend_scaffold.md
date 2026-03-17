# Backend Scaffold Notes

## Flutter side
- `main.dart` は Firebase 初期化付き repository を優先し、失敗時は fake repository に落ちます。
- `AppBootstrapScreen` が `sessionProvider` を見て、オンボーディングか通常導線かを分岐します。
- `HomeScreen` は Riverpod 経由で chat stream / character / pending message を扱います。
- `DiaryScreen` は `dailySummaries` を読む形に差し替えています。
- `ImageScreen` は最新画像状態と履歴を読む形に差し替えています。

## Backend side
- `backend/` に Cloud Run 用 Express サービス骨組みを追加しています。
- Firestore read/write と認証検証の構造を固定しています。
- `chat/messages` は Gemini on Vertex AI に接続済みです。
- `character` / `image` / `daily refresh` はまだ service 層の stub 実装です。

## Manual Firebase / GCP work still required
1. Firebase プロジェクト作成と匿名認証有効化
2. Firestore 作成と `firestore.rules` 適用
3. FlutterFire 設定ファイルの生成
4. Cloud Run / Secret Manager / Cloud Scheduler / Cloud Storage の有効化
5. `backend/` の依存インストールと Cloud Run デプロイ
6. `BACKEND_BASE_URL` と必要 secret を Flutter / Cloud Run へ設定

## Suggested rollout order
1. `flutterfire configure`
2. `firebase deploy --only firestore:rules`
3. `cd backend && npm install && npm run check`
4. Cloud Run へ deploy
5. `flutter run --dart-define=USE_FIREBASE=true --dart-define=BACKEND_BASE_URL=...`

## Current Cloud Run redeploy command
PowerShell:

```powershell
$sa = "mo-kun-backend@gdgoc-2026-mo-kun.iam.gserviceaccount.com"

gcloud run deploy mo-kun-api --source backend --region asia-northeast1 --allow-unauthenticated --service-account $sa --set-env-vars "GOOGLE_CLOUD_PROJECT=gdgoc-2026-mo-kun,VERTEX_LOCATION=global,GEMINI_MODEL=gemini-2.5-flash,GEMINI_TEMPERATURE=0.7,GEMINI_MAX_OUTPUT_TOKENS=220,IMAGE_MODEL=imagen" --set-secrets "DAILY_REFRESH_SECRET=DAILY_REFRESH_SECRET:latest"
```

## Manual verification after deploy
1. `flutter run --dart-define=BACKEND_BASE_URL=https://<cloud-run-url>`
2. オンボーディング済みユーザーで Home を開く
3. 2〜3往復メッセージを送る
4. 以前の固定文ではなく、入力内容に依存した返答になることを確認する
5. 失敗時はアプリ側で再送できることを確認する

## Troubleshooting
- `assistant_generation_failed`
  - Vertex AI 呼び出し失敗です。Cloud Run logs を確認してください。
- model availability error
  - `GEMINI_MODEL=gemini-2.5-flash` と `VERTEX_LOCATION=global` を使って再 deploy してください。
- permission denied for Vertex AI
  - Cloud Run 実行 service account に Vertex AI 利用権限が付いているか確認してください。
- source deploy picks Flutter instead of backend
  - project root ではなく `--source backend` を使って deploy してください。
