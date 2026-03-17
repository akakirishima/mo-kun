import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/diary_screen.dart';

import '../../../test_support/fake_app.dart';

void main() {
  testWidgets('renders AI diary cover and latest summary entry', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapWithTestApp(child: DiaryScreen(onSettingsTap: () {})),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('diary-screen')), findsOneWidget);
    expect(find.text('AI Diary'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey<String>('diary-book-page-view')),
      const Offset(-420, 0),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('小さく前進した日'), findsOneWidget);
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
}
