# mo-kun
ハッカソンチーム: もーくん

# デジタル生命体育成アプリケーション「自分育成たまごっち（仮称）」
GDGoC Japan Hackathon 2026 参加プロジェクト
テーマ: `Brand New "Hello World."`

## Overview
本プロジェクトは、AI キャラクターを介してユーザー自身の自己研鑽を促進するデジタル生命体育成アプリケーションです。
日々の行動をシステムに報告することで、生成 AI が内容を解析し、内部パラメータの増減とキャラクターの変化に反映します。

## Tech Stack
- Frontend: Flutter 3.41.2 (stable)
- Backend / Infrastructure: Google Cloud / Firebase
- AI / ML: Gemini API, Vertex AI

## Quick Start
このリポジトリは Flutter アプリとして初期化済みです。
セットアップ後は以下で起動確認できます。

```bash
flutter pub get
flutter doctor -v
flutter devices
flutter run
```

詳細なセットアップ手順は [docs/setup/flutter.md] を参照してください。
Git 運用ルールは [docs/git-rules.md] を参照してください。

## Setup Notes
- 作業は必ず `main` から作業ブランチを切ってから始めてください
- Flutter はチーム全員で `3.41.2 stable` に揃えてください
- 今回の初回ターゲットは Android です
- Mac メンバーもまずは Android 開発可能な状態を目標にします
- iOS は将来対応を見据えて前提だけ整理し、今回の完了条件には含めません

## Project Structure
- `lib/main.dart`: 起動確認用の最小画面
- `test/widget_test.dart`: 最小起動確認テスト
- `android/`: Android プラットフォーム設定
- `docs/setup/flutter.md`: Flutter セットアップ手順
- `docs/git-rules.md`: Git / PR 運用ルール

## Development Status
- [x] リポジトリの初期化
- [x] Flutter 環境構築
- [ ] UI プロトタイプの設計
- [ ] Gemini / Vertex AI のプロンプトエンジニアリングと検証
- [ ] フロントエンド / バックエンドの実装

---
This repository is for the GDGoC Japan Hackathon 2026.
