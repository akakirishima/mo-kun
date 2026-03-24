import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdgoc_2026_prototype/core/app/app_models.dart';
import 'package:gdgoc_2026_prototype/core/app/app_providers.dart';
import 'package:gdgoc_2026_prototype/core/app/fake_app_repository.dart';
import 'package:gdgoc_2026_prototype/core/app/image_url_resolver.dart';
import 'package:gdgoc_2026_prototype/features/home/presentation/home_screen.dart';
import 'package:gdgoc_2026_prototype/features/home/presentation/home_voice.dart';
import 'package:gdgoc_2026_prototype/features/home/presentation/widgets/home_room_stage.dart';

import '../../../test_support/fake_app.dart';
import '../../../test_support/mock_network_images.dart';

class _FakeImageUrlResolver extends ImageUrlResolver {
  _FakeImageUrlResolver(this.mapping);

  final Map<String, String> mapping;

  @override
  Future<String?> resolve(String? rawUrl) async {
    if (rawUrl == null) {
      return null;
    }
    return mapping[rawUrl] ?? rawUrl;
  }
}

class _FakeVoiceRecorder implements VoiceRecorderController {
  bool _isRecording = false;

  @override
  Future<void> cancel() async {
    _isRecording = false;
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<bool> ensurePermission() async => true;

  @override
  Future<void> start() async {
    _isRecording = true;
  }

  @override
  Future<RecordedVoiceClip?> stop() async {
    if (!_isRecording) {
      return null;
    }
    _isRecording = false;
    return RecordedVoiceClip(
      audioBytes: Uint8List.fromList(const <int>[1, 2, 3, 4]),
      mimeType: 'audio/wav',
      durationMs: 1200,
    );
  }
}

class _FakeVoicePlayer implements VoicePlayerController {
  int playCount = 0;

  @override
  Future<void> dispose() async {}

  @override
  Future<void> play(Uint8List audioBytes, {required String mimeType}) async {
    playCount += 1;
  }

  @override
  Future<void> stop() async {}
}

FakeAppRepository _buildRepository({
  required String latestImageUrl,
  String? latestVideoUrl,
  String? latestSquareVideoUrl,
}) {
  final now = DateTime(2026, 3, 18, 10, 0);
  return FakeAppRepository(
    initialSession: const AppSession(
      userId: 'test-user',
      needsOnboarding: false,
      characterId: 'test-character',
      threadId: 'test-thread',
    ),
    initialCharacter: CharacterSnapshot(
      id: 'test-character',
      name: 'Self',
      personaPrompt: '自分の流れを静かに整理して返す内なる声。',
      visualPromptBase: '会話内容に応じて見た目が少し変わる自己投影キャラクター。',
      imageStatus: CharacterImageStatus.ready,
      videoStatus: CharacterVideoStatus.idle,
      latestImageUrl: latestImageUrl,
      latestVideoUrl: latestVideoUrl,
      latestSquareVideoUrl: latestSquareVideoUrl,
      posterImageUrl: latestImageUrl,
      lastGeneratedAt: now,
      starterGreeting: '今日は何を残したい？',
    ),
    initialDailyBubble: DailyBubble(
      dateKey: '2026-03-18',
      text: '昨日の段取りは残っている。今日はひとつだけ進めよう、自分。',
      generatedAt: now,
      sourceDateKey: '2026-03-17',
    ),
    initialMessages: <ChatMessage>[
      ChatMessage(
        id: 'assistant-1',
        role: ChatRole.assistant,
        text: 'おはよう。昨日の積み上げ、ちゃんと覚えてるよ。',
        createdAt: now.subtract(const Duration(minutes: 3)),
      ),
    ],
  );
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 20,
}) async {
  for (var index = 0; index < maxPumps; index += 1) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
}

Future<HomeRoomStage> _pumpUntilStage(
  WidgetTester tester, {
  required bool Function(HomeRoomStage stage) predicate,
  int maxPumps = 20,
}) async {
  late HomeRoomStage stage;
  for (var index = 0; index < maxPumps; index += 1) {
    await tester.pump(const Duration(milliseconds: 50));
    stage = tester.widget<HomeRoomStage>(find.byType(HomeRoomStage));
    if (predicate(stage)) {
      return stage;
    }
  }
  return tester.widget<HomeRoomStage>(find.byType(HomeRoomStage));
}

void main() {
  testWidgets('renders the background image, daily bubble, room stage, and talk button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapWithTestApp(
        child: HomeScreen(onSettingsTap: nullHandler, onDiaryTap: nullHandler),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('home-background-image')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('home-daily-bubble')),
      findsOneWidget,
    );
    expect(find.textContaining('今日はひとつだけ進めよう'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('home-room-stage')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('home-talk-button')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('home-action-photo')), findsNothing);
    expect(find.byKey(const ValueKey<String>('home-diary-entry')), findsNothing);
  });

  testWidgets('renders the generated character image when available', (
    WidgetTester tester,
  ) async {
    const rawUrl =
        'gs://demo-bucket/characters/test-user/imageHistory/demo.png';
    const resolvedUrl = 'https://example.com/resolved-home-stage.png';

    await mockNetworkImages(() async {
      await tester.pumpWidget(
        wrapWithTestApp(
          repository: _buildRepository(latestImageUrl: rawUrl),
          overrides: [
            imageUrlResolverProvider.overrideWithValue(
              _FakeImageUrlResolver(const {rawUrl: resolvedUrl}),
            ),
          ],
          child: HomeScreen(
            onSettingsTap: nullHandler,
            onDiaryTap: nullHandler,
          ),
        ),
      );
      await tester.pump();
      await _pumpUntilFound(
        tester,
        find.byKey(const ValueKey<String>('home-room-stage-image')),
      );

      final image = tester.widget<Image>(
        find.byKey(const ValueKey<String>('home-room-stage-image')),
      );
      expect((image.image as NetworkImage).url, resolvedUrl);
      expect(image.fit, BoxFit.cover);
    });
  });

  testWidgets('prefers the square video url for the home stage', (
    WidgetTester tester,
  ) async {
    const rawImageUrl =
        'gs://demo-bucket/characters/test-user/imageHistory/demo.png';
    const rawVideoUrl =
        'gs://demo-bucket/characters/test-user/videoHistory/demo.mp4';
    const rawSquareVideoUrl =
        'gs://demo-bucket/characters/test-user/videoHistory/demo-square.mp4';
    const resolvedImageUrl = 'https://example.com/resolved-home-stage.png';
    const resolvedVideoUrl = 'https://example.com/resolved-home-stage.mp4';
    const resolvedSquareVideoUrl =
        'https://example.com/resolved-home-stage-square.mp4';

    await tester.pumpWidget(
      wrapWithTestApp(
        repository: _buildRepository(
          latestImageUrl: rawImageUrl,
          latestVideoUrl: rawVideoUrl,
          latestSquareVideoUrl: rawSquareVideoUrl,
        ),
        overrides: [
          imageUrlResolverProvider.overrideWithValue(
            _FakeImageUrlResolver(const {
              rawImageUrl: resolvedImageUrl,
              rawVideoUrl: resolvedVideoUrl,
              rawSquareVideoUrl: resolvedSquareVideoUrl,
            }),
          ),
        ],
        child: HomeScreen(onSettingsTap: nullHandler, onDiaryTap: nullHandler),
      ),
    );
    final stage = await _pumpUntilStage(
      tester,
      predicate: (stage) =>
          stage.videoUrl == resolvedSquareVideoUrl &&
          stage.imageUrl == resolvedImageUrl,
    );
    expect(stage.videoUrl, resolvedSquareVideoUrl);
    expect(stage.imageUrl, resolvedImageUrl);
  });

  testWidgets('opens voice mode and shows transcript plus reply text', (
    WidgetTester tester,
  ) async {
    final fakePlayer = _FakeVoicePlayer();

    await tester.pumpWidget(
      wrapWithTestApp(
        child: HomeScreen(
          onSettingsTap: nullHandler,
          onDiaryTap: nullHandler,
          voiceRecorder: _FakeVoiceRecorder(),
          voicePlayer: fakePlayer,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey<String>('home-talk-button')));
    await tester.tap(
      find.byKey(const ValueKey<String>('home-talk-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('home-voice-panel')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('home-voice-primary-button')),
    );
    await tester.pump();
    expect(find.text('送信する'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('home-voice-primary-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('今日は音声で話した内容を残した'), findsOneWidget);
    expect(find.textContaining('今日はひとつだけ進めてみよう'), findsWidgets);
    expect(fakePlayer.playCount, 1);
  });
}

void nullHandler() {}
