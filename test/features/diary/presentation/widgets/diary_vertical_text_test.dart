import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/widgets/diary_vertical_text.dart';

void main() {
  testWidgets('uses height to increase rows and reduce early column breaks', (
    WidgetTester tester,
  ) async {
    const text = 'あいうえおかきくけこさしすせそたちつてと';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 240,
              height: 320,
              child: DiaryVerticalText(
                text: text,
                color: Colors.black,
                fontSize: 20,
                columnPitch: 36,
                rowPitch: 24,
              ),
            ),
          ),
        ),
      ),
    );

    final columnFinder = find.byWidgetPredicate((widget) {
      final key = widget.key;
      return key is ValueKey<String> &&
          key.value.startsWith('diary-vertical-column-');
    });

    expect(columnFinder, findsNWidgets(2));
  });

  testWidgets('avoids punctuation at the top of a newly wrapped column', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 220,
              height: 126,
              child: DiaryVerticalText(
                text: 'あいうえおかきくけこ、さ',
                color: Colors.black,
                fontSize: 20,
                columnPitch: 36,
                rowPitch: 24,
              ),
            ),
          ),
        ),
      ),
    );

    final thirdColumnText = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byKey(const ValueKey<String>('diary-vertical-column-2')),
            matching: find.byType(Text),
          ),
        )
        .map((widget) => widget.data)
        .whereType<String>()
        .toList();

    expect(thirdColumnText.first, isNot('、'));
    expect(thirdColumnText, contains('、'));
  });

  testWidgets('keeps columns aligned on a fixed right-side pitch', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 220,
              height: 180,
              child: DiaryVerticalText(
                text: 'あいうえおかきくけこさしすせそ',
                color: Colors.black,
                fontSize: 20,
                columnPitch: 36,
                rowPitch: 24,
              ),
            ),
          ),
        ),
      ),
    );

    final firstColumn = tester.getTopLeft(
      find.byKey(const ValueKey<String>('diary-vertical-column-0')),
    );
    final secondColumn = tester.getTopLeft(
      find.byKey(const ValueKey<String>('diary-vertical-column-1')),
    );

    expect((secondColumn.dx - firstColumn.dx).abs(), closeTo(36, 0.1));
  });

  testWidgets('avoids opening quotes at the bottom of a wrapped column', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 220,
              height: 126,
              child: DiaryVerticalText(
                text: 'あいうえお「かきくけこ」',
                color: Colors.black,
                fontSize: 20,
                columnPitch: 36,
                rowPitch: 24,
              ),
            ),
          ),
        ),
      ),
    );

    final secondColumnText = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byKey(const ValueKey<String>('diary-vertical-column-1')),
            matching: find.byType(Text),
          ),
        )
        .map((widget) => widget.data)
        .whereType<String>()
        .toList();

    expect(secondColumnText.last, isNot('「'));
    expect(secondColumnText, contains('「'));
  });
}
