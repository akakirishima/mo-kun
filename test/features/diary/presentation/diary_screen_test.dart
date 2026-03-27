import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdgoc_2026_prototype/core/app/app_date.dart';
import 'package:gdgoc_2026_prototype/core/app/app_models.dart';
import 'package:gdgoc_2026_prototype/core/app/fake_app_repository.dart';
import 'package:gdgoc_2026_prototype/core/app/image_url_resolver.dart';
import 'package:gdgoc_2026_prototype/core/app/app_providers.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/diary_screen.dart';
import 'package:page_turn_animation/page_turn_animation.dart';

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
  const diaryScreen = DiaryScreen(enableCoverTurnTeaser: false);
  final appNow = resolveAppDate(DateTime.now());
  final currentMonthStart = DateTime(appNow.year, appNow.month);
  final previousMonthStart = DateTime(appNow.year, appNow.month - 1);
  final currentMonthLabel = '${appNow.month}月';
  final previousMonthLabel =
      '${DateTime(appNow.year, appNow.month - 1).month}月';
  final recordedDays = _currentMonthRecordedDays();
  final firstRecordedDay = recordedDays.reduce((left, right) {
    return left < right ? left : right;
  });
  final lastRecordedDay = recordedDays.reduce((left, right) {
    return left > right ? left : right;
  });
  final lastRecordedPageIndex = recordedDays.length;
  final todayDayNumber = appNow.day;
  final unrecordedDay = _pickUnrecordedDay(recordedDays);

  testWidgets('renders the pink calendar cover and only recorded-day entries', (
    WidgetTester tester,
  ) async {
    await mockNetworkImages(() async {
      await tester.pumpWidget(
        wrapWithTestApp(
          child: diaryScreen,
          overrides: [
            imageUrlResolverProvider.overrideWithValue(
              _FakeImageUrlResolver(const {
                'https://example.com/today.png':
                    'https://example.com/today.png',
                'https://example.com/last-month.png':
                    'https://example.com/last-month.png',
              }),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('diary-screen')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('diary-cover-page')),
        findsOneWidget,
      );
      expect(find.text(currentMonthLabel), findsWidgets);
      expect(
        find.byKey(const ValueKey<String>('diary-cover-calendar')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('diary-cover-bookshelf-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('diary-settings-button')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('diary-cover-previous-month')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('diary-cover-next-month')),
        findsNothing,
      );
      expect(find.text('${recordedDays.length}日ぶん'), findsNothing);
      expect(find.text('${recordedDays.length}件の記録'), findsNothing);
      expect(find.textContaining('まだこの日の会話要約はありません'), findsNothing);

      await tester.drag(
        find.byKey(const ValueKey<String>('diary-book-page-view')),
        const Offset(-420, 0),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(ValueKey<String>('diary-entry-page-$firstRecordedDay')),
        findsOneWidget,
      );
    });
  });

  testWidgets('plays the cover turn teaser without leaving the cover', (
    WidgetTester tester,
  ) async {
    const teaserScreen = DiaryScreen(enableCoverTurnTeaser: true);

    await tester.pumpWidget(wrapWithTestApp(child: teaserScreen));
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('diary-cover-turn-teaser')),
      findsNothing,
    );

    await tester.pump(const Duration(milliseconds: 900));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 25));
      if (find
          .byKey(const ValueKey<String>('diary-cover-turn-teaser'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }

    final teaserFinder = find.byKey(
      const ValueKey<String>('diary-cover-turn-teaser'),
    );
    expect(teaserFinder, findsOneWidget);

    await tester.pump(const Duration(milliseconds: 80));

    final teaser = tester.widget<PageTurnAnimation>(teaserFinder);
    expect(teaser.animation.value, greaterThan(0.0));
    expect(teaser.animation.value, lessThanOrEqualTo(0.25));

    await tester.pump(const Duration(milliseconds: 750));
    await tester.pump(const Duration(milliseconds: 650));

    expect(
      find.byKey(const ValueKey<String>('diary-cover-page')),
      findsOneWidget,
    );
    expect(_findKeysWithPrefix('diary-entry-page-'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('does not run the teaser after moving to an entry page', (
    WidgetTester tester,
  ) async {
    const teaserScreen = DiaryScreen(enableCoverTurnTeaser: true);

    await tester.pumpWidget(wrapWithTestApp(child: teaserScreen));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey<String>('diary-book-page-view')),
      const Offset(-420, 0),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(ValueKey<String>('diary-entry-page-$firstRecordedDay')),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 5));

    expect(
      find.byKey(const ValueKey<String>('diary-cover-turn-teaser')),
      findsNothing,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('opens the selector sheet from the cover', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrapWithTestApp(child: diaryScreen));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('diary-cover-selector')),
      warnIfMissed: false,
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

  testWidgets('opens the bookshelf and selects a recorded month', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrapWithTestApp(child: diaryScreen));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('diary-cover-bookshelf-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('diary-shelf-screen')),
      findsOneWidget,
    );

    final currentShelfBook = find.byKey(
      ValueKey<String>('diary-shelf-book-${_shelfBookKey(currentMonthStart)}'),
    );
    final previousShelfBook = find.byKey(
      ValueKey<String>('diary-shelf-book-${_shelfBookKey(previousMonthStart)}'),
    );
    expect(currentShelfBook, findsOneWidget);
    expect(previousShelfBook, findsOneWidget);
    expect(
      tester.getTopLeft(currentShelfBook).dx,
      lessThan(tester.getTopLeft(previousShelfBook).dx),
    );

    await tester.tap(previousShelfBook, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('diary-shelf-screen')),
      findsNothing,
    );
    expect(find.text(previousMonthLabel), findsWidgets);
    expect(
      find.byKey(const ValueKey<String>('diary-cover-calendar')),
      findsOneWidget,
    );
  });

  testWidgets('keeps the calendar frame rect fixed across months', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrapWithTestApp(child: diaryScreen));
    await tester.pumpAndSettle();

    final currentRect = tester.getRect(
      find.byKey(const ValueKey<String>('diary-cover-calendar')),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('diary-cover-selector')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('diary-selector-previous-month')),
    );
    await tester.pumpAndSettle();

    final previousRect = tester.getRect(
      find.byKey(const ValueKey<String>('diary-cover-calendar')),
    );

    expect(previousRect.top, currentRect.top);
    expect(previousRect.left, currentRect.left);
    expect(previousRect.right, currentRect.right);
    expect(previousRect.height, currentRect.height);
  });

  testWidgets('moves month from the selector sheet', (
    WidgetTester tester,
  ) async {
    await mockNetworkImages(() async {
      await tester.pumpWidget(
        wrapWithTestApp(
          child: diaryScreen,
          overrides: [
            imageUrlResolverProvider.overrideWithValue(
              _FakeImageUrlResolver(const {
                'https://example.com/today.png':
                    'https://example.com/today.png',
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
        warnIfMissed: false,
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
      expect(find.text(previousMonthLabel), findsWidgets);
    });
  });

  testWidgets('shows recorded day markers and a today ring on the cover', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrapWithTestApp(child: diaryScreen));
    await tester.pumpAndSettle();

    expect(
      find.byKey(ValueKey<String>('diary-cover-day-today-$todayDayNumber')),
      findsOneWidget,
    );
    expect(
      _findKeysWithPrefix('diary-cover-day-recorded-'),
      findsNWidgets(recordedDays.length),
    );
    for (final day in recordedDays) {
      expect(
        find.byKey(ValueKey<String>('diary-cover-day-recorded-$day')),
        findsOneWidget,
      );
    }
  });

  testWidgets('does not show a today ring on past months', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrapWithTestApp(child: diaryScreen));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('diary-cover-bookshelf-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        ValueKey<String>(
          'diary-shelf-book-${_shelfBookKey(previousMonthStart)}',
        ),
      ),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(_findKeysWithPrefix('diary-cover-day-today-'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('diary-cover-day-recorded-20')),
      findsOneWidget,
    );
  });

  testWidgets('opens the recorded day entry when a recorded date is tapped', (
    WidgetTester tester,
  ) async {
    await mockNetworkImages(() async {
      await tester.pumpWidget(
        wrapWithTestApp(
          child: diaryScreen,
          overrides: [
            imageUrlResolverProvider.overrideWithValue(
              _FakeImageUrlResolver(const {
                'https://example.com/today.png':
                    'https://example.com/today.png',
              }),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final recordedDayButton = find.byKey(
        ValueKey<String>('diary-cover-day-button-$lastRecordedDay'),
      );
      expect(recordedDayButton, findsOneWidget);

      await tester.tap(recordedDayButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(
        find.byKey(ValueKey<String>('diary-entry-page-$lastRecordedDay')),
        findsOneWidget,
      );
    });
  });

  testWidgets('opens the selected page from the selector sheet', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrapWithTestApp(child: diaryScreen));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('diary-cover-selector')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        ValueKey<String>('diary-day-selector-page-$lastRecordedPageIndex'),
      ),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(ValueKey<String>('diary-entry-page-$lastRecordedDay')),
      findsOneWidget,
    );
  });

  testWidgets('swipes back from the first entry to the cover', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrapWithTestApp(child: diaryScreen));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey<String>('diary-book-page-view')),
      const Offset(-420, 0),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(ValueKey<String>('diary-entry-page-$firstRecordedDay')),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const ValueKey<String>('diary-book-page-view')),
      const Offset(420, 0),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('diary-cover-page')),
      findsOneWidget,
    );
  });

  testWidgets('keeps unrecorded days non interactive on the cover', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrapWithTestApp(child: diaryScreen));
    await tester.pumpAndSettle();

    final unrecordedDayButton = find.byKey(
      ValueKey<String>('diary-cover-day-button-$unrecordedDay'),
    );
    expect(unrecordedDayButton, findsOneWidget);

    await tester.tap(unrecordedDayButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('diary-cover-page')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey<String>('diary-entry-page-$unrecordedDay')),
      findsNothing,
    );
  });

  testWidgets('keeps the cover in place when swiping right on the first page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrapWithTestApp(child: diaryScreen));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey<String>('diary-book-page-view')),
      const Offset(240, 0),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('diary-cover-page')),
      findsOneWidget,
    );
  });

  testWidgets('keeps the last page in place when swiping left at the end', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrapWithTestApp(child: diaryScreen));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(ValueKey<String>('diary-cover-day-button-$lastRecordedDay')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey<String>('diary-book-page-view')),
      const Offset(-420, 0),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(ValueKey<String>('diary-entry-page-$lastRecordedDay')),
      findsOneWidget,
    );
  });

  testWidgets('snaps back when a drag does not cross the threshold', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrapWithTestApp(child: diaryScreen));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey<String>('diary-book-page-view')),
      const Offset(-90, 0),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('diary-cover-page')),
      findsOneWidget,
    );
    expect(_findKeysWithPrefix('diary-entry-page-'), findsNothing);
  });

  testWidgets(
    'renders cover and entry without layout exceptions on a compact phone viewport',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(750, 1334);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await mockNetworkImages(() async {
        await tester.pumpWidget(
          wrapWithTestApp(
            child: diaryScreen,
            overrides: [
              imageUrlResolverProvider.overrideWithValue(
                _FakeImageUrlResolver(const {
                  'https://example.com/today.png':
                      'https://example.com/today.png',
                }),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('diary-cover-page')),
          findsOneWidget,
        );

        await tester.drag(
          find.byKey(const ValueKey<String>('diary-book-page-view')),
          const Offset(-320, 0),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(ValueKey<String>('diary-entry-page-$firstRecordedDay')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    },
  );

  testWidgets('keeps the bookshelf button disabled when no books exist', (
    WidgetTester tester,
  ) async {
    final emptyRepository = FakeAppRepository(
      initialSession: const AppSession(
        userId: 'empty-user',
        needsOnboarding: false,
        characterId: 'empty-character',
        threadId: 'empty-thread',
      ),
      initialCharacter: CharacterSnapshot(
        id: 'empty-character',
        name: 'Self',
        personaPrompt: '静かに見守る内なる声。',
        visualPromptBase: 'やわらかな自己投影キャラクター。',
        imageStatus: CharacterImageStatus.ready,
        videoStatus: CharacterVideoStatus.idle,
        lastGeneratedAt: DateTime.now(),
      ),
      initialMessages: const <ChatMessage>[],
      initialSummaries: const <DailySummary>[],
      initialUserProfile: const UserProfileInput(
        displayName: 'Empty',
        goal: '続ける',
        partnerStyle: '静かに寄り添う',
        weakPoints: <String>['三日坊主'],
      ),
    );

    await tester.pumpWidget(
      wrapWithTestApp(child: diaryScreen, repository: emptyRepository),
    );
    await tester.pumpAndSettle();

    final shelfButton = find.byKey(
      const ValueKey<String>('diary-cover-bookshelf-button'),
    );
    expect(shelfButton, findsOneWidget);

    await tester.tap(shelfButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('diary-shelf-screen')),
      findsNothing,
    );
  });
}

Set<int> _currentMonthRecordedDays() {
  final now = resolveAppDate(DateTime.now());
  final previousDay = resolveAppDate(
    DateTime.now().subtract(const Duration(days: 1)),
  );
  return <int>{
    now.day,
    if (previousDay.year == now.year && previousDay.month == now.month)
      previousDay.day,
  };
}

int _pickUnrecordedDay(Set<int> recordedDays) {
  for (final candidate in <int>[1, 2, 3, 4, 5, 10, 15, 20, 25, 28]) {
    if (!recordedDays.contains(candidate)) {
      return candidate;
    }
  }
  return 28;
}

Finder _findKeysWithPrefix(String prefix) {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> && key.value.startsWith(prefix);
  });
}

String _shelfBookKey(DateTime monthStart) {
  final month = monthStart.month.toString().padLeft(2, '0');
  return '${monthStart.year}-$month';
}
