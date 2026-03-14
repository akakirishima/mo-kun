import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdgoc_2026_prototype/features/image/presentation/image_screen.dart';

void main() {
  testWidgets('renders highlight categories and the AI Select gallery', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: ImageScreen(onSettingsTap: () {})),
    );

    expect(find.byKey(const ValueKey<String>('image-screen')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('image-settings-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('image-post-fab')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('image-highlight-row')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('image-highlight-item-meal')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('image-highlight-item-workout')),
      findsOneWidget,
    );
    expect(find.text('食事'), findsOneWidget);
    expect(find.text('筋トレ'), findsOneWidget);
    expect(find.text('旅行'), findsOneWidget);
    expect(find.text('日常'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('image-ai-select-header')),
      findsOneWidget,
    );
    expect(find.text('AI Select'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('image-ai-select-grid')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('image-ai-select-item-sunset')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('image-ai-select-item-sunset')),
        matching: find.text('AI Pick · 旅行'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey<String>('image-post-fab')));
    await tester.pumpAndSettle();

    expect(find.text('投稿フローはこれから追加します'), findsOneWidget);
  });

  testWidgets('keeps the gallery stable on a narrow screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 690);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var settingsTapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: ImageScreen(onSettingsTap: () => settingsTapCount += 1),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey<String>('image-highlight-row')),
      const Offset(-120, 0),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey<String>('image-post-fab')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('image-ai-select-item-trip')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('image-settings-button')),
    );
    await tester.pumpAndSettle();
    expect(settingsTapCount, 1);
  });
}
