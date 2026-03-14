import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdgoc_2026_prototype/features/chat/presentation/chat_screen.dart';

void main() {
  testWidgets('renders the LINE-like top bar, messages, and input actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatScreen(onStartHomeCallTap: () {}, onSettingsTap: () {}),
        ),
      ),
    );

    expect(find.byKey(const ValueKey<String>('chat-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('chat-top-bar')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('chat-top-search')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('chat-top-phone')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('chat-settings-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('chat-message-list')),
      findsOneWidget,
    );
    expect(find.text('Mori'), findsWidgets);
    expect(find.text('今日'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('chat-input-bar')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('chat-input-camera')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('chat-input-image')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('chat-input-message-field')),
      findsOneWidget,
    );
    expect(find.text('メッセージ'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('chat-input-mic')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('chat-input-phone')),
      findsOneWidget,
    );
  });

  testWidgets(
    'shows the character avatar and keeps user messages right aligned',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatScreen(onStartHomeCallTap: () {}, onSettingsTap: () {}),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('chat-message-character-avatar')),
        findsOneWidget,
      );

      final userAlign = tester.widget<Align>(
        find.byKey(const ValueKey<String>('chat-message-user-align')),
      );
      final characterAlign = tester.widget<Align>(
        find.byKey(const ValueKey<String>('chat-message-character-align')),
      );

      expect(userAlign.alignment, Alignment.centerRight);
      expect(characterAlign.alignment, Alignment.centerLeft);
    },
  );

  testWidgets('does not overflow on a narrow screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 690);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatScreen(onStartHomeCallTap: () {}, onSettingsTap: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey<String>('chat-input-bar')),
      findsOneWidget,
    );
  });

  testWidgets('phone actions delegate to the Home talk shortcut', (
    WidgetTester tester,
  ) async {
    var phoneTapCount = 0;
    var didTapSettings = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatScreen(
            onStartHomeCallTap: () {
              phoneTapCount += 1;
            },
            onSettingsTap: () {
              didTapSettings = true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('chat-top-phone')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('chat-input-phone')));
    await tester.pumpAndSettle();

    expect(phoneTapCount, 2);

    await tester.tap(
      find.byKey(const ValueKey<String>('chat-settings-button')),
    );
    await tester.pumpAndSettle();

    expect(didTapSettings, isTrue);
  });
}
