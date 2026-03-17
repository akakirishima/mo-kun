import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdgoc_2026_prototype/core/app/app_models.dart';
import 'package:gdgoc_2026_prototype/core/app/app_providers.dart';
import 'package:gdgoc_2026_prototype/core/app/fake_app_repository.dart';
import 'package:gdgoc_2026_prototype/core/app/image_url_resolver.dart';
import 'package:gdgoc_2026_prototype/features/home/presentation/home_screen.dart';
import 'package:image_picker/image_picker.dart';

import '../../../test_support/fake_app.dart';

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

FakeAppRepository _buildRepository({required String latestImageUrl}) {
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
      name: 'Mori',
      personaPrompt: 'やわらかく励ます相棒。',
      visualPromptBase: '会話内容に応じて見た目が少し変わる相棒。',
      imageStatus: CharacterImageStatus.ready,
      latestImageUrl: latestImageUrl,
      lastGeneratedAt: now,
      starterGreeting: '今日も会えて嬉しいな。\n一緒にお話ししよ！',
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

void main() {
  testWidgets('renders the Mori card, room stage, and action buttons', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapWithTestApp(child: HomeScreen(onSettingsTap: nullHandler)),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('home-mori-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('home-room-stage')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('home-action-bar')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('home-action-chat')),
      findsOneWidget,
    );
  });

  testWidgets('renders the generated character image when available', (
    WidgetTester tester,
  ) async {
    const rawUrl = 'gs://demo-bucket/characters/test-user/imageHistory/demo.png';
    const resolvedUrl = 'https://example.com/resolved-home-stage.png';

    await tester.pumpWidget(
      wrapWithTestApp(
        repository: _buildRepository(latestImageUrl: rawUrl),
        overrides: [
          imageUrlResolverProvider.overrideWithValue(
            _FakeImageUrlResolver(const {rawUrl: resolvedUrl}),
          ),
        ],
        child: HomeScreen(onSettingsTap: nullHandler),
      ),
    );
    await tester.pumpAndSettle();

    final image = tester.widget<Image>(
      find.byKey(const ValueKey<String>('home-room-stage-image')),
    );
    expect((image.image as NetworkImage).url, resolvedUrl);
  });

  testWidgets('shows assistant history and sends a new pending message', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapWithTestApp(child: HomeScreen(onSettingsTap: nullHandler)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('home-action-chat')));
    await tester.pumpAndSettle();

    expect(find.textContaining('昨日の積み上げ'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey<String>('chat-input-message-field')),
      '今日は朝に散歩した',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('chat-input-send')));
    await tester.pumpAndSettle();
    expect(find.text('今日は朝に散歩した'), findsWidgets);
    expect(find.textContaining('反映しておくね'), findsOneWidget);
    final userTopLeft = tester.getTopLeft(
      find.byKey(const ValueKey<String>('home-user-bubble-0')).last,
    );
    final assistantTopLeft = tester.getTopLeft(
      find.byKey(const ValueKey<String>('home-assistant-bubble-1')),
    );
    expect(userTopLeft.dy, lessThan(assistantTopLeft.dy));
  });

  testWidgets('shows pending preview after gallery selection', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapWithTestApp(
        child: HomeScreen(
          onSettingsTap: nullHandler,
          pickImage: (source) async {
            expect(source, ImageSource.gallery);
            return XFile('/tmp/home-gallery.png');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('home-action-chat')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('chat-input-image')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('home-chat-pending-preview')),
      findsOneWidget,
    );
    expect(find.text('home-gallery.png'), findsOneWidget);
  });

  testWidgets('preserves draft text and sent messages across back navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapWithTestApp(child: HomeScreen(onSettingsTap: nullHandler)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('home-action-chat')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('chat-input-message-field')),
      'draft text',
    );
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey<String>('home-chat-back-button')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('home-action-chat')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey<String>('chat-input-message-field')),
          )
          .controller!
          .text,
      'draft text',
    );
  });
}

void nullHandler() {}
