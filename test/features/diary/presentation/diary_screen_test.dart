import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdgoc_2026_prototype/app/shell/widgets/glass_bottom_dock.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/diary_screen.dart';

Widget _buildDiaryTestApp({required VoidCallback onSettingsTap}) {
  return MaterialApp(
    home: MediaQuery(
      data: const MediaQueryData(
        padding: EdgeInsets.only(bottom: 92),
        viewPadding: EdgeInsets.only(bottom: 92),
      ),
      child: DiaryScreen(onSettingsTap: onSettingsTap),
    ),
  );
}

void main() {
  testWidgets('renders the diary cover, selector, and settings button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildDiaryTestApp(onSettingsTap: () {}));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('diary-screen')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('diary-settings-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('diary-cover-selector')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('diary-cover-page')),
      findsOneWidget,
    );
    expect(find.text('1ヶ月をめくる絵日記'), findsNothing);
    expect(find.textContaining('左右にスワイプして'), findsNothing);
  });

  testWidgets('cover selector opens the day selector sheet', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildDiaryTestApp(onSettingsTap: () {}));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('diary-cover-selector')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('diary-day-selector-sheet')),
      findsOneWidget,
    );
  });

  testWidgets('page swipe flips from the cover to the first diary page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildDiaryTestApp(onSettingsTap: () {}));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey<String>('diary-book-page-view')),
      const Offset(-420, 0),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('diary-entry-page-1')),
      findsOneWidget,
    );
    expect(find.text('3月1日'), findsOneWidget);
    expect(find.text('ゆっくり起動'), findsNothing);
    expect(find.text('なまえ'), findsNothing);
    expect(find.text('がつ'), findsNothing);
    expect(find.text('にち'), findsNothing);
    expect(find.text('ようび'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('diary-entry-meta-column-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('diary-entry-meta-glyph-column-1-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('diary-entry-meta-glyph-column-1-1')),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('diary-entry-meta-column-1')),
        matching: find.text('月'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('diary-entry-meta-column-1')),
        matching: find.text('曜'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('diary-entry-meta-column-1')),
        matching: find.text('日'),
      ),
      findsWidgets,
    );
  });

  testWidgets('entry date selector jumps to a chosen entry page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildDiaryTestApp(onSettingsTap: () {}));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey<String>('diary-book-page-view')),
      const Offset(-420, 0),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('diary-entry-date-selector-1')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('diary-day-selector-sheet')),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('diary-day-selector-page-14')),
      240,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey<String>('diary-day-selector-sheet')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('diary-day-selector-page-14')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('diary-entry-page-14')),
      findsOneWidget,
    );
    expect(find.text('3月14日'), findsOneWidget);
    expect(find.text('寄り道の色'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('diary-entry-meta-column-14')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('diary-entry-meta-glyph-column-14-0')),
      findsOneWidget,
    );
    expect(find.text('土ようび'), findsNothing);
  });

  testWidgets('entry layout uses the page height more aggressively', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildDiaryTestApp(onSettingsTap: () {}));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey<String>('diary-book-page-view')),
      const Offset(-420, 0),
    );
    await tester.pumpAndSettle();

    final pageRect = tester.getRect(
      find.byKey(const ValueKey<String>('diary-entry-page-1')),
    );
    final illustrationRect = tester.getRect(
      find.byKey(const ValueKey<String>('diary-entry-illustration-1')),
    );
    final writingRect = tester.getRect(
      find.byKey(const ValueKey<String>('diary-entry-writing-paper-1')),
    );

    expect(
      illustrationRect.top - pageRect.top,
      lessThan(pageRect.height * 0.11),
    );
    expect(
      pageRect.bottom - writingRect.bottom,
      greaterThanOrEqualTo(GlassBottomDock.reservedBottomSpacing - 20),
    );
    expect(
      pageRect.bottom - writingRect.bottom,
      lessThanOrEqualTo(GlassBottomDock.reservedBottomSpacing + 12),
    );
    expect(writingRect.height, greaterThan(pageRect.height * 0.43));
    expect(
      find.byKey(const ValueKey<String>('diary-entry-meta-column-1')),
      findsOneWidget,
    );
  });

  testWidgets('settings button delegates and stays stable on narrow screens', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 690);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var settingsTapCount = 0;

    await tester.pumpWidget(
      _buildDiaryTestApp(onSettingsTap: () => settingsTapCount += 1),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('diary-settings-button')),
    );
    await tester.pumpAndSettle();

    expect(settingsTapCount, 1);
    expect(tester.takeException(), isNull);
  });
}
