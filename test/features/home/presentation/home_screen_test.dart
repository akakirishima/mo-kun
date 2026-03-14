import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdgoc_2026_prototype/features/home/presentation/home_screen.dart';

void main() {
  testWidgets('renders the transcript card, room stage, and talk button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          onStartCallTap: () {},
          transcriptText: 'うん、ちゃんと聞こえてるよ。',
          onSettingsTap: () {},
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('home-transcript-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('home-room-stage')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('home-talk-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('home-settings-button')),
      findsOneWidget,
    );
    expect(find.text('今日の一言'), findsOneWidget);
    expect(find.text('話しかける'), findsOneWidget);
    expect(find.text('うん、ちゃんと聞こえてるよ。'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('home-shortcut-row')),
      findsNothing,
    );
  });

  testWidgets(
    'talk button calls onStartCallTap and stays stable on narrow screens',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 690);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var callTapCount = 0;
      var settingsTapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            onStartCallTap: () => callTapCount += 1,
            transcriptText: 'ここに文字起こしが表示されるよ。',
            onSettingsTap: () => settingsTapCount += 1,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('home-settings-button')),
      );
      await tester.pumpAndSettle();
      expect(settingsTapCount, 1);

      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('home-talk-button')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('home-talk-button')));
      await tester.pumpAndSettle();

      expect(callTapCount, 1);
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey<String>('home-transcript-text')),
        findsOneWidget,
      );
    },
  );
}
