# Backend Scaffold Notes

## Flutter side
- `main.dart` は Firebase 初期化付き repository を優先し、失敗時は fake repository に落ちます。
- `AppBootstrapScreen` が `sessionProvider` を見て、オンボーディングか通常導線かを分岐します。
- `HomeScreen` は Riverpod 経由で chat stream / character / pending message を扱います。
- `DiaryScreen` は `dailySummaries` を読む形に差し替えています。
- `ImageScreen` は最新画像状態と履歴を読む形に差し替えています。

## Backend side
- `backend/` に Cloud Run 用 Express サービス骨組みを追加しています。
- Firestore read/write と認証検証は構造だけ先に固定しています。
- text reply / image generation / daily refresh は service 層に stub 実装を置いています。

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
