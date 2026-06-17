# Backend Implementation Notes

`Hello new me` backend の実装メモです。公開リポジトリで読まれることを前提に、構成と判断理由だけを残しています。

## App / backend の接続

- Flutter app は `BACKEND_BASE_URL` を使って HTTP API に接続する
- live voice は `BACKEND_WS_URL` を使って WebSocket 接続する
- Firebase Auth の user ID を基準に、Firestore 上の user / character / daily data を関連付ける
- Firebase 未設定のローカル preview では、UI 確認用の fallback repository を使える構成にしている

## AI service

- Chat は character profile、recent messages、daily context を prompt に含める
- daily summary は会話後に再生成し、当日の記録を更新する
- daily bubble は前日 summary をもとに短く生成する
- image prompt は character base、visualEvolutionMemo、当日の summary、room scene items を組み合わせる

## Live voice

- Flutter は PCM 16kHz mono を chunk で送る
- backend は Gemini Live API へ stateful session として relay する
- assistant 音声は PCM 24kHz mono を逐次返す
- 保存対象は final transcript と assistant text に限定する
- partial transcript は UI 表示用であり、履歴には保存しない
- barge-in 時は client 側で再生バッファを破棄する

## 日付境界

- app / backend ともに `03:00 JST` を dateKey の境界にする
- 深夜帯の活動を前日の延長として扱い、Diary、bubble、image history の基準日をそろえる

## Firestore / Storage

主な collection:

- `users`
- `characters`
- `chatThreads`
- `dailySummaries`
- `dailyBubbles`

画像は Storage の `characters/{uid}/...` に保存し、Firestore には最新 URL と履歴 metadata を保存する。

## Environment

環境変数名は [backend/README.md](../../backend/README.md) を参照します。

公開 README には実 project ID、bucket 名、secret 値を固定しません。

## 検証観点

- chat message 送信時に assistant response と daily summary が更新される
- live voice で final transcript のみが保存される
- image regeneration で Storage と Firestore の両方が更新される
- daily refresh job が bubble と image を更新する
- `03:00 JST` の dateKey が app / backend で一致する

## 今後の改善

- prompt の評価観点をログから切り出す
- character image の一貫性を高める
- Live API reconnect 時の UX を改善する
- Cloud Run の負荷と料金を見ながら concurrency / min instances を調整する
