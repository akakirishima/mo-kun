import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdgoc_2026_prototype/core/app/app_models.dart';
import 'package:gdgoc_2026_prototype/core/app/app_providers.dart';
import 'package:gdgoc_2026_prototype/core/app/fake_app_repository.dart';
import 'package:gdgoc_2026_prototype/core/app/image_url_resolver.dart';
import 'package:gdgoc_2026_prototype/features/image/presentation/image_screen.dart';

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

FakeAppRepository _buildRepository({required String latestImageUrl}) {
  final now = DateTime(2026, 3, 16, 10, 0);
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
    initialSummary: DailySummary(
      dateKey: '2026-03-16',
      title: '小さく前進した日',
      diaryBody: '今日は報告を1つ送って、UIを整えた。'
          '\n明日は朝に短く報告して流れを作れたらいいな。',
      mood: '前向き',
      doneThings: const <String>['報告を1つ送った', 'UIを整えた'],
      reflection: 'やることを言葉にすると次の動きが見えた。',
      tomorrowNote: '朝に短く報告して流れを作る。',
      generatedAt: now,
    ),
    initialImageHistory: <CharacterImageVersion>[
      CharacterImageVersion(
        id: 'history-1',
        title: '昨日の報告を反映した姿',
        promptExcerpt: '筋トレを頑張ったので少したくましい印象',
        status: CharacterImageStatus.ready,
        generatedAt: now,
        imageUrl: latestImageUrl,
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

void main() {
  testWidgets('renders the latest image status and history list', (
    WidgetTester tester,
  ) async {
    await mockNetworkImages(() async {
      await tester.pumpWidget(
        wrapWithTestApp(
          repository: _buildRepository(
            latestImageUrl: 'https://example.com/generated/latest.png',
          ),
          child: ImageScreen(onSettingsTap: () {}),
        ),
      );
      await tester.pump();
      await _pumpUntilFound(
        tester,
        find.byKey(const ValueKey<String>('image-latest-preview')),
      );
      await _pumpUntilFound(
        tester,
        find.byKey(const ValueKey<String>('image-history-preview-0')),
      );

      expect(find.byKey(const ValueKey<String>('image-screen')), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('image-latest-card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('image-latest-status')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('image-latest-preview')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey<String>('image-latest-status')))
            .data,
        '更新済み',
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey<String>('image-history-header')),
        240,
        scrollable: find.byType(Scrollable),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('image-history-header')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('image-history-item-0')),
        findsOneWidget,
      );
      final latestImage = tester.widget<Image>(
        find.byKey(const ValueKey<String>('image-latest-preview')),
      );
      expect(latestImage.fit, BoxFit.contain);

      final latestMediaSize = tester.getSize(
        find.byKey(const ValueKey<String>('image-latest-media')),
      );
      expect(latestMediaSize.width / latestMediaSize.height, closeTo(1.6, 0.05));
    });
  });

  testWidgets('resolves gs urls before rendering the latest image', (
    WidgetTester tester,
  ) async {
    const rawUrl = 'gs://demo-bucket/characters/test-user/imageHistory/demo.png';
    const resolvedUrl = 'https://example.com/resolved.png';

    await mockNetworkImages(() async {
      await tester.pumpWidget(
        wrapWithTestApp(
          repository: _buildRepository(latestImageUrl: rawUrl),
          overrides: [
            imageUrlResolverProvider.overrideWithValue(
              _FakeImageUrlResolver(const {rawUrl: resolvedUrl}),
            ),
          ],
          child: ImageScreen(onSettingsTap: () {}),
        ),
      );
      await tester.pump();
      await _pumpUntilFound(
        tester,
        find.byKey(const ValueKey<String>('image-latest-preview')),
      );

      final image = tester.widget<Image>(
        find.byKey(const ValueKey<String>('image-latest-preview')),
      );
      expect((image.image as NetworkImage).url, resolvedUrl);
      expect(image.fit, BoxFit.contain);
    });
  });

  testWidgets('floating action button opens regenerate sheet and submits', (
    WidgetTester tester,
  ) async {
    final repository = _buildRepository(
      latestImageUrl: 'https://example.com/generated/latest.png',
    );

    await tester.pumpWidget(
      wrapWithTestApp(
        repository: repository,
        child: ImageScreen(onSettingsTap: () {}),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byKey(const ValueKey<String>('image-post-fab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      find.byKey(const ValueKey<String>('image-regenerate-sheet')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('image-regenerate-input')),
      '少し春っぽい空気感にしたい',
    );
    await tester.tap(find.byKey(const ValueKey<String>('image-regenerate-submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('画像の再生成を開始しました'), findsOneWidget);
    expect(
      repository.initializeSession().then((session) => session.characterId),
      completion('test-character'),
    );
  });
}
