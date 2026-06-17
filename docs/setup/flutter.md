# Flutter Setup Guide

## Target
- Flutter version: `3.41.x` stable
- Primary platform: Android
- Supported setup readers: Windows / Mac

## Git Workflow
作業は必ず `main` から作業ブランチを切ってから始めてください。

```bash
git checkout main
git pull
git checkout -b chore/flutter-bootstrap
```

## Flutter Version Policy
チーム全員で Flutter `3.41.x` (stable) に揃えてください。
「各自でその時点の最新 stable にする」運用にはしません。バージョン差で再現性が落ちるためです。

確認コマンド:

```bash
flutter --version
```

期待する出力の先頭:

```text
Flutter 3.41.x • channel stable
```

## Common Setup
Windows / Mac 共通で必要なもの:

1. Flutter `3.41.x` stable
2. Android Studio
3. Android SDK
4. Git

セットアップ確認:

```bash
flutter doctor -v
```

最低限、Android 開発に必要な項目が通っていれば今回の対象としては十分です。

## Windows Setup
このリポジトリの初回開発対象は Android です。
Windows では以下を満たしてください。

1. Android Studio をインストールする
2. Android SDK / platform-tools を導入する
3. Android ライセンスを受諾する
4. Android エミュレータまたは USB デバッグ有効な実機を用意する

確認コマンド:

```bash
flutter doctor -v
flutter emulators
flutter devices
```

補足:
- Windows デスクトップ向け Visual Studio は今回の必須要件ではありません
- `flutter doctor` で Visual Studio が未導入でも、Android 開発だけなら着手できます

## Mac Setup
Mac メンバーも、今回の必須ラインは Android 開発可能な状態です。

1. Flutter `3.41.x` stable を導入する
2. Android Studio と Android SDK を導入する
3. Android Emulator または実機を用意する
4. `flutter doctor -v` で Android 関連を確認する

将来 iOS も扱う前提として、以下は早めに揃えておくと移行が楽です。

1. Xcode
2. Xcode Command Line Tools
3. iOS Simulator

例:

```bash
xcode-select --install
sudo xcodebuild -runFirstLaunch
```

ただし、今回の完了条件には iOS ビルド確認は含めていません。

## Validation
セットアップ後は以下で起動確認できます。

```bash
flutter pub get
flutter doctor -v
flutter devices
flutter run
```
