# Backend Scaffold Notes

## Flutter side
- `main.dart` は Firebase 初期化付き repository を優先し、失敗時は fake repository に落ちます。
- `AppBootstrapScreen` が `sessionProvider` を見て、オンボーディングか通常導線かを分岐します。
- `HomeScreen` は Riverpod 経由で chat stream / character / daily bubble / pending message を扱う本番 UI です。
- `HomeScreen` は中央キャラ、吹き出し、音声モード、写真モード、チャットモードを持ちます。
- `DiaryScreen` は `dailySummaries` を読みます。
- `ImageScreen` は最新画像状態と履歴を読み、手動再生成を叩けます。
- `HomeScreen` 中央のキャラクター表示も、最新の生成画像を優先して表示します。

## Backend side
- `backend/` は Cloud Run 用 Express サービスです。
- Firestore read/write と認証検証の構造を固定しています。
- `chat/messages` は Gemini on Vertex AI に接続済みです。
- `chat/voice` は Speech-to-Text と Text-to-Speech に接続済みです。
- `characters/image` は Gemini image generation と Cloud Storage 保存に接続済みです。
- `daily refresh` は毎日 `03:00 JST` 基準で summary / bubble / image 更新を行う前提です。
- `visualEvolutionMemo` は直近 7 日分の daily summary から再構築し、`characters/{uid}` に保持します。
- backend の実配線は `backend/src/index.ts` が基準です。

## Manual Firebase / GCP work still required
1. Firebase プロジェクト作成と匿名認証有効化
2. Firestore 作成と `firestore.rules` 適用
3. FlutterFire 設定ファイルの生成
4. Cloud Run / Secret Manager / Cloud Scheduler / Cloud Storage / Vertex AI / Speech-to-Text / Text-to-Speech の有効化
5. `backend/` の依存インストールと Cloud Run デプロイ
6. `BACKEND_BASE_URL` と必要 secret を Flutter / Cloud Run へ設定

## Suggested rollout order
1. `flutterfire configure`
2. `firebase deploy --only "firestore:rules,storage"`
3. `cd backend && npm install && npm run check`
4. Cloud Run へ deploy
5. `flutter run --dart-define=BACKEND_BASE_URL=...`

## Current Cloud Run redeploy command
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
  --set-env-vars "GOOGLE_CLOUD_PROJECT=$project,VERTEX_LOCATION=global,GEMINI_MODEL=gemini-2.5-flash,GEMINI_IMAGE_MODEL=gemini-2.5-flash-image,GEMINI_TEMPERATURE=0.7,GEMINI_MAX_OUTPUT_TOKENS=220,IMAGE_BUCKET=$bucket,SPEECH_LANGUAGE_CODE=ja-JP,TTS_LANGUAGE_CODE=ja-JP,TTS_AUDIO_ENCODING=MP3" `
  --set-secrets "DAILY_REFRESH_SECRET=DAILY_REFRESH_SECRET:latest"
```

## Manual verification after deploy
1. `flutter run --dart-define=BACKEND_BASE_URL=https://mo-kun-api-922529284142.asia-northeast1.run.app`
2. オンボーディング済みユーザーで Home を開く
3. 上部が固定ヘッダーではなく吹き出し表示になっていることを確認する
4. 音声ボタンから録音し、transcript と assistant 音声付き返答が返ることを確認する
5. チャット導線でも返答が返り、当日の summary が反映されることを確認する
6. `Image` タブから再生成メモを入れて、最新画像が切り替わることを確認する
7. `Home` 中央にも同じ最新画像が反映されることを確認する
8. `POST /v1/jobs/daily-refresh` を手動で叩いて summary / bubble / image が更新されることを確認する

## Troubleshooting
- `assistant_generation_failed`
  - Vertex AI 呼び出し失敗です。Cloud Run logs を確認してください。
- speech recognition / permission denied
  - Cloud Run 実行 service account に `roles/speech.client` が付いているか確認してください。
- TTS 失敗でテキストだけ返る
  - `audioStatus=failed` が返っていないか確認し、Cloud Run logs を見てください。
- model availability error
  - `GEMINI_MODEL=gemini-2.5-flash`、`GEMINI_IMAGE_MODEL=gemini-2.5-flash-image`、`VERTEX_LOCATION=global` を使って再 deploy してください。
- image download URL error
  - `storage.rules` を deploy し、backend が `characters/{uid}/...` 配下へ保存しているか確認してください。
- source deploy picks Flutter instead of backend
  - project root ではなく `--source backend` を使って deploy してください。
