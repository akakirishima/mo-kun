# Backend MVP Plan

このメモは、`Hello new me` backend の MVP 範囲と設計判断をまとめたものです。

現在の主語は「AI と話すアプリ」ではなく、日々の記録から `自己投影キャラクター` を更新する体験です。

## MVP の目的

- Flutter app から初回オンボーディング、会話、音声、画像更新を呼び出せるようにする
- Firebase Auth / Firestore / Storage を使って、ユーザーごとの状態を永続化する
- Vertex AI Gemini を使って、会話応答、日次要約、翌朝 bubble、画像生成を分担する
- Cloud Run 上で運用できる API と WebSocket relay を用意する
- `03:00 JST` を日付境界として、日記・bubble・画像更新の基準日をそろえる

## 対象機能

- セッション初期化
- キャラクター生成
- テキストチャット
- push-to-talk 音声会話
- Gemini Live API relay
- daily summary 生成
- daily bubble 生成
- キャラクター画像生成
- 日次 refresh job

## 非対象

- SNS / フレンド機能
- 課金
- 本人声クローン
- 複雑なゲーム内ステータス
- 長期分析基盤

## 主要フロー

### 初回セッション

1. Flutter app がプロフィール、目標、接し方を送る
2. backend が Firebase Auth のユーザーを前提に状態を作る
3. Gemini で persona prompt と starter greeting を生成する
4. 初期 character image を生成して Storage に保存する
5. Firestore に character metadata を保存する

### テキストチャット

1. 過去の会話と character context を取得する
2. Gemini へ会話生成を依頼する
3. user / assistant message を Firestore に保存する
4. 当日の daily summary を再生成する
5. Flutter app へ応答を返す

### 音声会話

1. Flutter app が PCM 音声を送る
2. backend が Gemini Live API へ relay する
3. assistant 音声と transcript を受け取る
4. final transcript のみを Firestore に保存する
5. daily summary を更新する

### 日次更新

1. Cloud Scheduler が daily refresh endpoint を呼ぶ
2. backend が `03:00 JST` 基準で対象日を解決する
3. 前日 summary から当日の bubble を生成する
4. 直近 summary と当日メモから visualEvolutionMemo を更新する
5. character image を再生成する

## データ構成

```text
users/{uid}
characters/{uid}
chatThreads/{threadId}
chatThreads/{threadId}/messages/{messageId}
users/{uid}/dailySummaries/{dateKey}
users/{uid}/dailyBubbles/{dateKey}
```

画像は Cloud Storage の `characters/{uid}/...` 配下に保存し、Firestore には URL と履歴 metadata を保持します。

## 受け入れ基準

- 初回入力から character が生成される
- Home で chat 応答、bubble、最新画像が表示できる
- 音声会話で assistant 音声が返り、final transcript が保存される
- Diary で記録がある日だけを表示できる
- Image タブから再生成できる
- 日次 job が daily summary / bubble / image を更新できる

## 残課題

- Cloud Scheduler の本番設定
- prompt と UX copy の継続改善
- 画像生成の一貫性向上
- WebSocket 運用時の Cloud Run concurrency / timeout 調整
