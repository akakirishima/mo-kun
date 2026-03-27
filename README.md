# デジタル生命体育成アプリケーション「自分育成たまごっち（仮称）」
GDGoC Japan Hackathon 2026 参加プロジェクト  
テーマ: `Brand New "Hello World."`

## Overview
本プロジェクトは、AI キャラクターを介してユーザー自身の自己研鑽を促進するデジタル生命体育成アプリケーションです。  
現在のコンセプトは「相棒と話す」ではなく、`自分を投影したキャラクター / 自分の内なる声` と対話することです。  
日々の行動や会話内容をもとに、生成 AI が返答、日次サマリー、日次吹き出し、キャラクター画像の変化を生成します。

## Product Description
### raise you〜小さな友達〜 とは
`raise you〜小さな友達〜` は、ユーザーの毎日の行動や気持ちを AI キャラクターに写し取り、会話・記録・見た目の変化として返してくれる「自己育成のための小さな相棒」です。  
このプロダクトが目指しているのは、タスク管理や習慣化アプリのように「正しく続けなければいけない」と感じさせることではなく、ユーザーが自分自身の変化をもっとやさしく観察できる状態をつくることです。

多くの自己管理サービスは、記録を残してもその情報が感情的な実感につながりにくく、途中で開かれなくなってしまいます。  
そこで本プロダクトでは、記録を単なるログとして蓄積するのではなく、`自分の内なる声を持った AI キャラクター` に変換します。  
ユーザーが話したこと、送った写真、声の内容、その日の振り返りが、相棒の返答、翌朝のひとこと、日記、部屋の小物、キャラクターの表情や雰囲気として少しずつ反映されるため、「自分の頑張りが育っていく」感覚を継続的に得られます。

### 解決したい課題
- 三日坊主になりやすい習慣化・自己管理の継続率の低さ
- 日記や記録アプリが「書いて終わり」になりやすいこと
- 自己対話をしたくても、ひとりでは前向きな振り返りを続けにくいこと
- 努力や感情の変化が可視化されず、成長実感が薄れやすいこと

`raise you〜小さな友達〜` は、努力の結果を数字だけで見せるのではなく、キャラクターとの関係性と世界観の変化に変換することで、日々の小さな報告を自然に続けられる体験をつくっています。

### 体験の流れ
1. ユーザーは最初に、呼ばれたい名前、頑張りたいこと、どう接してほしいか、苦手なことを入力します。
2. その情報をもとに、ユーザー自身を投影した AI キャラクターの人格設定と初期ビジュアルを生成します。
3. 以後は `Home` を中心に、テキスト、音声、写真でその日の出来事を気軽に報告します。
4. AI は会話として自然に返答するだけでなく、その日の会話内容を再解釈して日次サマリーを更新します。
5. 翌朝には、前日の振り返りをもとにした短い吹き出しが表示され、「今日の一歩」を促します。
6. さらに、直近の積み重ねをもとにキャラクター画像が変化し、部屋の中の小物や雰囲気にもその日の出来事がにじむように反映されます。
7. `Diary` では記録が残った日だけをめくって見返せるため、自分の行動と気持ちの蓄積を物語のように振り返れます。

### 主な機能
#### 1. 内なる声としての AI チャット
一般的な「何でも答える AI アシスタント」ではなく、ユーザーの目標や希望する接し方を反映した、`自分を支えるための人格` として返答する設計です。  
返答は日本語で、短すぎる一言では終わらず、親しい友人のようなトーンで自然に会話を広げます。  
これにより、命令される感覚ではなく、自分の気持ちを受け止めながら次の一歩を整理する体験を生み出します。

#### 2. 音声による push-to-talk 会話
ユーザーはボタン長押しで録音し、声でその日のことを話せます。  
バックエンドでは `Speech-to-Text -> Gemini による返答生成 -> Text-to-Speech` の流れを実行し、返答はテキストと音声の両方で返します。  
手入力よりも心理的負荷が低く、移動中や夜の振り返りなど、テキスト入力が面倒な場面でも使いやすい点が特徴です。

#### 3. 写真を通じた行動ログ化
写真付きでメッセージを送ると、AI が写真の内容を軽く解釈し、食事、活動、場所などを推定した上で会話に織り込みます。  
たとえば、食事写真であれば料理名、外出先の写真であれば場所の候補を自然に返答し、曖昧な場合のみ確認します。  
これにより、「文章で説明するほどではない日常」も、気軽に自己記録へ取り込めます。

#### 4. 自動で育つ AI Diary
会話や音声、写真付き投稿の内容は、その日のうちに `daily summary` として再構成されます。  
サマリーは単なる箇条書きではなく、日記本文、タイトル、気分、できたこと、振り返り、明日のメモとして保存されます。  
ユーザーが明示的に日記を書かなくても、会話の延長でその日の記録が残る点が大きな特徴です。

#### 5. 翌朝のひとこと吹き出し
前日のサマリーをもとに、その日の始まりに短い吹き出し文を生成します。  
これは通知的なリマインドではなく、昨日の流れを受け止めた上で、今日の一歩をやさしく促すメッセージです。  
アプリを開いた瞬間に「昨日から今日へ続いている感覚」をつくり、再訪のきっかけを生みます。

#### 6. キャラクター画像の進化
このプロダクトの中心的な価値の一つが、`記録が見た目に変わること` です。  
ユーザーの目標や接し方、直近 7 日分の振り返り、当日のサマリー、当日の会話から抽出した部屋の小物情報をもとに、Gemini で最新のキャラクター画像を生成します。

画像生成では、毎回まったく別の絵を作るのではなく、`同じ部屋・同じキャラクターが少しずつ変わっていく` ことを重視しています。  
部屋のレイアウトは固定し、中央のキャラクターを主役に保ちながら、表情、姿勢、服装ディテール、空気感、小物などにその日の積み重ねをにじませます。  
たとえば、運動を頑張った日はダンベルや水筒、作業を進めた日は机まわりの小物など、日々の報告が部屋の中に具体物として現れます。

#### 7. ホームでのライブ感ある表示
`Home` では最新の生成画像に加えて、生成済みの動画があればそれを優先表示します。  
静止画だけでなく、部屋の中で小さく動く相棒として見せることで、単なるプロフィール画像ではない「存在感」を持たせています。  
ユーザーにとってアプリを開くこと自体が、成長した自分に会いに行く体験になります。

### 技術的な特徴
フロントエンドは Flutter で実装し、`Home / Diary / Image / Settings` を中心としたモバイルアプリとして構築しています。  
バックエンドは TypeScript / Express を Cloud Run 上で動かし、認証・データ保存・画像保存には Firebase を利用しています。  
AI 連携には Vertex AI 上の Gemini を採用し、用途ごとに役割を分けています。

- 会話生成: `gemini-2.5-pro`
- 日次サマリー生成: `gemini-2.5-pro`
- 翌朝の吹き出し生成: `gemini-2.5-pro`
- 写真の軽量解析: `gemini-2.5-pro`
- キャラクター画像生成: `gemini-2.5-flash-image`
- 音声認識: Cloud Speech-to-Text
- 音声返答: Cloud Text-to-Speech

さらに、アプリとバックエンドの両方で `03:00 JST` を日付境界として統一しています。  
これは深夜帯の行動が「前日の延長」として感じられることを考慮した設計であり、日記や吹き出し、画像更新の基準日をユーザー体験に合わせています。

### このプロダクトならではの新しさ
本プロダクトの新しさは、AI を「答えをくれる存在」としてではなく、`自分の変化を育てて返してくれる存在` として設計している点にあります。  
チャット、音声、写真、日記、画像生成はそれぞれ独立した機能ではなく、すべてがひとつの相棒体験につながっています。

- 会話すると、その日の記録が育つ
- 記録がたまると、翌朝の言葉が変わる
- 振り返りが積み重なると、キャラクターの姿が変わる
- 変化した姿を見ることで、また話したくなる

この循環によって、自己管理を「義務」ではなく「関係性の継続」に変えることを目指しました。

### 想定ユースケース
- 習慣化が苦手で、堅いタスク管理アプリが続かない人
- 目標はあるが、自分を責めずに継続したい人
- 日記を書きたいが、文章としてまとめる負荷が高い人
- 毎日の小さな行動を、かわいい相棒の成長として見たい人
- 自己理解やセルフリフレクションを、もっと感情的に続けたい人

### 今後の展望
現在でも、会話、音声、写真、日次サマリー、吹き出し、画像更新まで一連の体験は動作しています。  
今後は、Cloud Scheduler を用いた日次更新の完全自動化、キャラクター表現の精度向上、継続利用を支える UX 改善を進めることで、より長期的に寄り添うプロダクトへ発展させていく予定です。

## Current Product Shape
- `HomeScreen` が現在の本番 UI です。会話導線は `Home` に統合しています。
- `Home` では中央のキャラクター画像と、そのキャラクターが話しているように見える日次吹き出しを表示します。
- `Home` の下部アクションは `音声 / 写真 / チャット` です。
- 音声会話は push-to-talk 方式で、録音した音声を backend に送り、`STT -> AI返答生成 -> TTS` の往復を行います。
- assistant の返答は `テキスト表示 + 音声再生` で返ります。
- `Diary` では月送りで daily summary を見返せます。表示対象は記録がある日だけです。
- `Image` では Gemini で生成したキャラクター画像の最新状態と履歴を表示し、手動再生成できます。
- `Home` 画面中央も、生成済みの最新キャラクター画像を優先表示します。

## Tech Stack
- Frontend: Flutter 3.41.2 (stable)
- Backend: TypeScript / Express on Cloud Run
- Data / Auth / Storage: Firebase, Firestore, Cloud Storage
- AI / ML: Vertex AI, Gemini, Cloud Speech-to-Text, Cloud Text-to-Speech

## AI Integration
- chat model: `gemini-2.5-pro`
- image model: `gemini-2.5-flash-image`
- `VERTEX_LOCATION=global` を前提にしています

Daily summary では次の JSON を Gemini から生成します。
- `title`
- `mood`
- `doneThings`
- `reflection`
- `tomorrowNote`

chat 送信時点で当日 summary を再生成し、`users/{uid}/dailySummaries/{dateKey}` に保存します。  
日次吹き出しは前日 summary をもとに生成し、`users/{uid}/dailyBubbles/{dateKey}` に保存します。  
日付境界は `03:00 JST` です。

画像生成では次の情報を使います。
- `character.visualPromptBase`
- 直近 7 日分の daily summary から圧縮した `visualEvolutionMemo`
- 当日の daily summary
- 当日の summary / 会話から抽出した room scene items
- 手動再生成時の optional note

生成画像は「固定レイアウトの room template + 中央のキャラクター」を基本構図にしています。  
その日の報告内容は、部屋の中の小物として最大 4 件まで prompt に反映します。  
生成画像は Cloud Storage に保存し、Firestore には最新画像と履歴メタデータを保持します。

## Quick Start
```bash
flutter pub get
flutter doctor -v
flutter devices
flutter run
```

Cloud Run 上の backend を使う場合:

```bash
flutter run --dart-define=BACKEND_BASE_URL=https://mo-kun-api-922529284142.asia-northeast1.run.app
```

詳細なセットアップ手順は [`docs/setup/flutter.md`](docs/setup/flutter.md) を参照してください。  
Git 運用ルールは [`docs/git-rules.md`](docs/git-rules.md) を参照してください。

## Backend / Infra Notes
- backend の実配線は `backend/src/index.ts` が基準です
- AI 連携の中核は `backend/src/services/ai-service.ts` です
- 音声処理は `backend/src/services/speech-service.ts` です
- 日次吹き出し生成は `backend/src/services/daily-bubble-service.ts` です
- 画像生成、Cloud Storage 保存、Firestore 更新は `backend/src/services/character-image-service.ts` でまとめています
- 手動再生成 API は `POST /v1/characters/image`
- 音声会話 API は `POST /v1/chat/voice`
- 日次更新 API は `POST /v1/jobs/daily-refresh`
- `POST /v1/chat/messages` と `POST /v1/chat/voice` のどちらでも当日の daily summary を再生成します
- 日付境界は app / backend ともに `03:00 JST` です
- Firestore / Storage rules は `firebase.json` から deploy します

backend の詳細は [`backend/README.md`](backend/README.md) と [`docs/backend/implementation_notes.md`](docs/backend/implementation_notes.md) を参照してください。

## Project Structure
- `lib/main.dart`: アプリ起動エントリポイント
- `lib/app/`: `MaterialApp`、下部ナビ、タブ定義
- `lib/core/`: repository, provider, theme, shared utilities
- `lib/features/`: `home / diary / image / chat / onboarding` ごとの画面実装
- `backend/`: Cloud Run 向け Express サービス
- `docs/backend/`: backend 実装メモとデプロイ補足
- `test/app/`: アプリシェルの widget test
- `test/features/`: 各 feature の widget test

## Verification
最低限の確認ポイント:
- `Home` 上部が固定ヘッダーではなく吹き出し表示になる
- `Home` で Gemini の chat 応答が返る
- `Home` の音声ボタンから録音できる
- 音声送信後に transcript と assistant 音声付き返答が返る
- `Home` で送った会話内容が当日の `Diary` に反映される
- `Image` タブから画像を再生成できる
- `Home` 中央に最新生成画像が反映される
- `Diary` が未記録日ではなく、記録がある日だけを表示する
- `POST /v1/jobs/daily-refresh` で daily summary / daily bubble / 画像更新が動く

## Development Status
- [x] Flutter app の土台整理
- [x] backend MVP foundation
- [x] Gemini chat integration
- [x] push-to-talk 音声会話
- [x] daily bubble generation
- [x] Gemini image generation + Cloud Storage persistence
- [x] Home / Diary / Image の backend 接続
- [ ] Cloud Scheduler を含む本番運用の最終整備
- [ ] prompt / UX の継続改善

---
This repository is for the GDGoC Japan Hackathon 2026.
