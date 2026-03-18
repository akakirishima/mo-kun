import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdgoc_2026_prototype/core/app/image_url_resolver.dart';
import 'package:gdgoc_2026_prototype/core/app/app_providers.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/diary_screen.dart';

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

void main() {
  testWidgets('renders AI diary cover and only recorded-day entries', (
    WidgetTester tester,
  ) async {
    await mockNetworkImages(() async {
      await tester.pumpWidget(
        wrapWithTestApp(
          child: DiaryScreen(onSettingsTap: () {}),
          overrides: [
            imageUrlResolverProvider.overrideWithValue(
              _FakeImageUrlResolver(const {
                'https://example.com/today.png': 'https://example.com/today.png',
                'https://example.com/last-month.png':
                    'https://example.com/last-month.png',
              }),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey<String>('diary-screen')), findsOneWidget);
      expect(find.text('AI Diary'), findsOneWidget);
      expect(find.textContaining('まだこの日の会話要約はありません'), findsNothing);

      await tester.drag(
        find.byKey(const ValueKey<String>('diary-book-page-view')),
        const Offset(-420, 0),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('言葉を整えた日'), findsOneWidget);
    });
  });

  testWidgets('opens the selector sheet from the cover', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapWithTestApp(child: DiaryScreen(onSettingsTap: () {})),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('diary-cover-selector')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('diary-day-selector-sheet')),
      findsOneWidget,
    );

    expect(
      find.byKey(const ValueKey<String>('diary-day-selector-sheet')),
      findsOneWidget,
    );
  });

  testWidgets('moves to the previous month from the cover', (
    WidgetTester tester,
  ) async {
    final expectedPreviousMonthLabel =
        '${DateTime(DateTime.now().year, DateTime.now().month - 1).month}月';

    await mockNetworkImages(() async {
      await tester.pumpWidget(
        wrapWithTestApp(
          child: DiaryScreen(onSettingsTap: () {}),
          overrides: [
            imageUrlResolverProvider.overrideWithValue(
              _FakeImageUrlResolver(const {
                'https://example.com/today.png': 'https://example.com/today.png',
                'https://example.com/last-month.png':
                    'https://example.com/last-month.png',
              }),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('diary-cover-previous-month')),
      );
      await tester.pumpAndSettle();

      expect(find.text(expectedPreviousMonthLabel), findsWidgets);
      expect(find.textContaining('先月の積み上げ'), findsWidgets);
    });
  });

  testWidgets('moves month from the selector sheet', (
    WidgetTester tester,
  ) async {
    final expectedPreviousMonthLabel =
        '${DateTime(DateTime.now().year, DateTime.now().month - 1).month}月';

    await mockNetworkImages(() async {
      await tester.pumpWidget(
        wrapWithTestApp(
          child: DiaryScreen(onSettingsTap: () {}),
          overrides: [
            imageUrlResolverProvider.overrideWithValue(
              _FakeImageUrlResolver(const {
                'https://example.com/today.png': 'https://example.com/today.png',
                'https://example.com/last-month.png':
                    'https://example.com/last-month.png',
              }),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('diary-cover-selector')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('diary-selector-previous-month')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('diary-day-selector-sheet')),
        findsNothing,
      );
      expect(find.text(expectedPreviousMonthLabel), findsWidgets);
      expect(find.textContaining('先月の積み上げ'), findsWidgets);
    });
  });
}
