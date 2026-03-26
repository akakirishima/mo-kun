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
  final currentMonthLabel = '${DateTime.now().month}月';
  final previousMonthLabel =
      '${DateTime(DateTime.now().year, DateTime.now().month - 1).month}月';
  final recordedDays = _currentMonthRecordedDays();
  final firstRecordedDay = recordedDays.reduce((left, right) {
    return left < right ? left : right;
  });
  final lastRecordedDay = recordedDays.reduce((left, right) {
    return left > right ? left : right;
  });
  final lastRecordedPageIndex = recordedDays.length;
  final todayDayNumber = DateTime.now().day;
  final unrecordedDay = _pickUnrecordedDay(recordedDays);

  testWidgets('renders the pink calendar cover and only recorded-day entries', (
    WidgetTester tester,
  ) async {
    await mockNetworkImages(() async {
      await tester.pumpWidget(
        wrapWithTestApp(
          child: const DiaryScreen(),
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
        find.byKey(const ValueKey<String>('diary-settings-button')),
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

  testWidgets('opens the selector sheet from the cover', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrapWithTestApp(child: const DiaryScreen()));
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

  testWidgets('moves to the previous month from the cover', (
    WidgetTester tester,
  ) async {
    await mockNetworkImages(() async {
      await tester.pumpWidget(
        wrapWithTestApp(
          child: const DiaryScreen(),
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
        find.byKey(const ValueKey<String>('diary-cover-previous-month')),
      );
      await tester.pumpAndSettle();

      expect(find.text(previousMonthLabel), findsWidgets);
      expect(
        find.byKey(const ValueKey<String>('diary-cover-calendar')),
        findsOneWidget,
      );
    });
  });

  testWidgets('keeps the calendar frame rect fixed across months', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrapWithTestApp(child: const DiaryScreen()));
    await tester.pumpAndSettle();

    final currentRect = tester.getRect(
      find.byKey(const ValueKey<String>('diary-cover-calendar')),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('diary-cover-previous-month')),
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
          child: const DiaryScreen(),
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
    await tester.pumpWidget(wrapWithTestApp(child: const DiaryScreen()));
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
    await tester.pumpWidget(wrapWithTestApp(child: const DiaryScreen()));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('diary-cover-previous-month')),
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
          child: const DiaryScreen(),
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
    await tester.pumpWidget(wrapWithTestApp(child: const DiaryScreen()));
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
    await tester.pumpWidget(wrapWithTestApp(child: const DiaryScreen()));
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
    await tester.pumpWidget(wrapWithTestApp(child: const DiaryScreen()));
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
    await tester.pumpWidget(wrapWithTestApp(child: const DiaryScreen()));
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
    await tester.pumpWidget(wrapWithTestApp(child: const DiaryScreen()));
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
    await tester.pumpWidget(wrapWithTestApp(child: const DiaryScreen()));
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
            child: const DiaryScreen(),
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
}

Set<int> _currentMonthRecordedDays() {
  final now = DateTime.now();
  final previousDay = now.subtract(const Duration(days: 1));
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
