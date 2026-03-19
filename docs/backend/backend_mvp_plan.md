# バックエンドMVP構成整理

このドキュメントは当初の MVP 計画メモを、現在の実装状態に合わせて更新したものです。  
古い「音声は stretch goal」「image は対象外」「相棒キャラ前提」という前提は、現状には合っていません。

## 1. 現在の目的
本プロジェクトでは、ユーザーが `自分自身を投影したキャラクター` と会話できる Flutter アプリを開発している。  
現在の会話手段は以下を対象としている。

- 初回のキャラクター生成
- テキストチャット
- 音声チャット（push-to-talk 方式）
- 日次吹き出し生成
- キャラクター画像生成と更新

今回の backend は、上記を Cloud Run 上で一通り成立させることを目的としている。

## 2. 現在の方針

### 2.1 採用方針
- フロントエンド: Flutter
- 認証: Firebase Authentication（匿名認証）
- データ保存: Cloud Firestore
- バックエンド API: Cloud Run
- 生成 AI: Vertex AI Gemini
- 音声: Cloud Speech-to-Text / Cloud Text-to-Speech

### 2.2 いま成立している MVP 体験
- ユーザー初回入力からキャラクターを生成できる
- 生成されたキャラクターとテキスト会話できる
- 生成されたキャラクターと音声会話できる
- 会話履歴を継続利用できる
- 会話内容から daily summary を生成できる
- 前日 summary をもとに当日の吹き出し文を生成できる
- キャラクター画像を生成し、履歴を保持できる

### 2.3 まだ対象外のもの
- リアルタイム双方向音声会話
- 本人声クローン
- 複雑なキャラクターステータス管理
- フレンド機能や SNS 的要素
- 通知、課金、分析基盤

## 3. プロダクトの考え方
本アプリでは、ユーザーの過去の会話履歴や daily summary を文脈として活用し、AI がその都度自然な返答を生成する。  
固定ステータスを加算するゲームではなく、`会話履歴ベースで継続する自己投影キャラクター` として設計している。

また、返答の立ち位置は「相棒」ではなく `自分の内なる声` を基本とする。  
そのため、UI 表現、返答文体、吹き出し文言はこの前提に寄せる。

## 4. 現在の主要フロー

### 4.1 キャラクター生成
1. Flutter でプロフィール入力
2. backend でキャラクター生成リクエストを受ける
3. 初期プロフィールとキャラクター設定を保存する
4. 初回画像を生成する
5. フロントへ生成結果を返す

### 4.2 テキスト会話
1. ユーザーの会話履歴を取得
2. Gemini に文脈付きで問い合わせ
3. 返答を生成
4. Firestore に保存
5. 当日の daily summary を再生成
6. フロントへ返却

### 4.3 音声会話
1. Flutter で録音
2. backend へ送信
3. 音声を文字起こし
4. Gemini で返答生成
5. 返答文を音声化
6. Firestore に transcript / assistant text を保存
7. テキストと音声をフロントへ返却

### 4.4 日次吹き出し
1. 当日 dateKey を解決
2. 前日 summary を取得
3. 当日の一言を生成
4. `dailyBubbles/{dateKey}` に保存
5. 当日中は同じ文を再利用

### 4.5 画像生成
1. 直近 summary を取得
2. `visualEvolutionMemo` を再構築
3. 当日の summary と scene items を prompt に組み込む
4. Gemini image generation を実行
5. Cloud Storage 保存と Firestore 更新を行う

## 5. 全体構成

```text
Flutter
 ├─ Firebase Auth（匿名認証）
 ├─ Firestore（ユーザー・日次要約・吹き出し・会話履歴）
 └─ Cloud Run API
      ├─ キャラクター生成API
      ├─ テキスト会話API
      ├─ 音声会話API
      ├─ 画像生成API
      └─ Vertex AI / STT / TTS 連携
```

## 6. 現在の保存データ

### users

```text
users/{userId}
- createdAt
- updatedAt
- displayName
- goal
- partnerStyle
- weakPoints: string[]
```

### daily summaries

```text
users/{userId}/dailySummaries/{dateKey}
- title
- mood
- doneThings
- reflection
- tomorrowNote
- generatedAt
```

### daily bubbles

```text
users/{userId}/dailyBubbles/{dateKey}
- text
- generatedAt
- sourceDateKey
```

### characters

```text
characters/{characterId}
- userId
- name
- personaPrompt
- visualPromptBase
- visualEvolutionMemo
- visualEvolutionUpdatedAt
- starterGreeting
- imageGenerationStatus
- lastGeneratedImageUrl
- lastImageGeneratedAt
```

### chat threads

```text
chatThreads/{threadId}
- userId
- createdAt
- updatedAt
```

### chat messages

```text
chatThreads/{threadId}/messages/{messageId}
- role: user | assistant
- text
- inputType: text | voice
- clientMessageId
- createdAt
```

## 7. 現在の API
- `POST /v1/session/initialize`
- `POST /v1/characters`
- `POST /v1/chat/messages`
- `POST /v1/chat/voice`
- `POST /v1/characters/image`
- `POST /v1/jobs/daily-refresh`

## 8. 現在の整理
現時点では、当初 stretch goal だった音声会話も backend 上で実装済みです。  
また image backend も対象外ではなく、現行構成の中核に入っています。

今後の主な論点は以下です。

1. 自己投影キャラクター向けの onboarding / prompt の継続改善
2. 吹き出し UI と日次メッセージの精度向上
3. 本人声に寄せる将来対応
4. Cloud Scheduler を含む本番運用の安定化
