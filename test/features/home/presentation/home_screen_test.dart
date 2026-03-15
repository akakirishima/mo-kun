import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdgoc_2026_prototype/features/home/presentation/home_screen.dart';

void main() {
  testWidgets('renders the Mori card, room stage, and action buttons', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HomeScreen(onSettingsTap: nullHandler)),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('home-mori-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('home-room-stage')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('home-action-bar')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('home-action-phone')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('home-action-photo')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('home-action-chat')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('home-settings-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('home-message-layer')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('home-chat-input-bar')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('home-chat-back-button')),
      findsNothing,
    );
    expect(find.text('Mori'), findsOneWidget);
    expect(find.text('今日も会えて嬉しいな。\n一緒にお話ししよ！'), findsOneWidget);

    final headerBottom = tester.getBottomLeft(
      find.byKey(const ValueKey<String>('home-mori-card')),
    );
    final roomTop = tester.getTopLeft(
      find.byKey(const ValueKey<String>('home-room-stage-shell')),
    );
    expect((roomTop.dy - headerBottom.dy).abs(), lessThan(12));

    final actionTop = tester.getTopLeft(
      find.byKey(const ValueKey<String>('home-action-bar')),
    );
    final roomBottom = tester.getBottomLeft(
      find.byKey(const ValueKey<String>('home-room-stage-shell')),
    );
    expect(actionTop.dy, greaterThan(roomBottom.dy));

    final settingsIcon = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('home-settings-button')),
        matching: find.byType(Icon),
      ),
    );
    expect(settingsIcon.icon, Icons.settings_outlined);
  });

  testWidgets('shows the chat layer only after tapping the chat action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HomeScreen(onSettingsTap: nullHandler)),
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('home-action-chat')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('home-message-layer')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('home-chat-input-bar')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('home-action-bar')), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('home-chat-back-button')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const ValueKey<String>('chat-input-send')),
          )
          .onPressed,
      isNull,
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('chat-input-message-field')),
      'メッセージは右、Mori は左で進めるね。',
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<IconButton>(
            find.byKey(const ValueKey<String>('chat-input-send')),
          )
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const ValueKey<String>('chat-input-send')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('home-user-bubble-0')),
      findsOneWidget,
    );
    expect(find.text('メッセージは右、Mori は左で進めるね。'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey<String>('chat-input-message-field')),
          )
          .controller!
          .text,
      isEmpty,
    );
  });

  testWidgets('keeps the room stage size when entering chat mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HomeScreen(onSettingsTap: nullHandler)),
      ),
    );

    final sizeBefore = tester.getSize(
      find.byKey(const ValueKey<String>('home-room-stage-shell')),
    );

    await tester.tap(find.byKey(const ValueKey<String>('home-action-chat')));
    await tester.pumpAndSettle();

    final sizeAfter = tester.getSize(
      find.byKey(const ValueKey<String>('home-room-stage-shell')),
    );

    expect(sizeAfter.width, closeTo(sizeBefore.width, 0.1));
    expect(sizeAfter.height, closeTo(sizeBefore.height, 0.1));
  });

  testWidgets('overlays the chat layer onto the room stage', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HomeScreen(onSettingsTap: nullHandler)),
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('home-action-chat')));
    await tester.pumpAndSettle();

    final roomBottom = tester.getBottomLeft(
      find.byKey(const ValueKey<String>('home-room-stage-shell')),
    );
    final messageLayerTop = tester.getTopLeft(
      find.byKey(const ValueKey<String>('home-message-layer')),
    );

    expect(messageLayerTop.dy, lessThan(roomBottom.dy));

    await tester.enterText(
      find.byKey(const ValueKey<String>('chat-input-message-field')),
      'overlay check',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('chat-input-send')));
    await tester.pumpAndSettle();

    final bubbleBottom = tester.getBottomLeft(
      find.byKey(const ValueKey<String>('home-user-bubble-0')),
    );
    final composerTop = tester.getTopLeft(
      find.byKey(const ValueKey<String>('home-chat-input-bar')),
    );

    expect(bubbleBottom.dy, lessThan(composerTop.dy));
  });

  testWidgets('keeps the chat input bar pinned near the screen bottom', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HomeScreen(onSettingsTap: nullHandler)),
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('home-action-chat')));
    await tester.pumpAndSettle();

    final screenBottom = tester.getBottomLeft(
      find.byKey(const ValueKey<String>('home-screen')),
    );
    final composerBottom = tester.getBottomLeft(
      find.byKey(const ValueKey<String>('home-chat-input-bar')),
    );

    expect(screenBottom.dy - composerBottom.dy, lessThan(32));
  });

  testWidgets('back button closes the chat UI and restores action buttons', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HomeScreen(onSettingsTap: nullHandler)),
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('home-action-chat')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('home-chat-input-bar')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('home-action-bar')), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('home-chat-back-button')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('home-chat-back-button')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('home-message-layer')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('home-chat-input-bar')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('home-chat-back-button')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('home-action-bar')),
      findsOneWidget,
    );
  });

  testWidgets('phone and photo modes are immersive and restore on back', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HomeScreen(onSettingsTap: nullHandler)),
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('home-action-phone')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('home-action-bar')), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('home-chat-back-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('home-chat-input-bar')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('home-chat-back-button')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('home-action-bar')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey<String>('home-action-photo')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('home-action-bar')), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('home-chat-back-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('home-chat-input-bar')),
      findsNothing,
    );
  });

  testWidgets('message layer scrolls after many messages', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HomeScreen(onSettingsTap: nullHandler)),
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('home-action-chat')));
    await tester.pumpAndSettle();

    const messages = [
      'first',
      'second',
      'third',
      'fourth',
      'fifth',
      'sixth',
      'seventh',
      'eighth',
    ];

    for (final message in messages) {
      await tester.enterText(
        find.byKey(const ValueKey<String>('chat-input-message-field')),
        message,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('chat-input-send')));
      await tester.pumpAndSettle();
    }

    final scrollableBefore = tester.state<ScrollableState>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('home-message-layer')),
        matching: find.byType(Scrollable),
      ),
    );
    final beforeOffset = scrollableBefore.position.pixels;
    scrollableBefore.position.jumpTo(math.max(beforeOffset - 180, 0));
    await tester.pump();
    final scrollableAfter = tester.state<ScrollableState>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('home-message-layer')),
        matching: find.byType(Scrollable),
      ),
    );
    final afterOffset = scrollableAfter.position.pixels;

    expect(afterOffset, isNot(closeTo(beforeOffset, 0.1)));
  });

  testWidgets('renders each sent message only once', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HomeScreen(onSettingsTap: nullHandler)),
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('home-action-chat')));
    await tester.pumpAndSettle();

    const messages = ['Hyuga', 'onion'];

    for (final message in messages) {
      await tester.enterText(
        find.byKey(const ValueKey<String>('chat-input-message-field')),
        message,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('chat-input-send')));
      await tester.pumpAndSettle();
    }

    for (final message in messages) {
      expect(find.text(message), findsOneWidget);
    }
  });

  testWidgets('preserves draft text and sent messages across back navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HomeScreen(onSettingsTap: nullHandler)),
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('home-action-chat')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('chat-input-message-field')),
      'sent message',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('chat-input-send')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('chat-input-message-field')),
      'draft text',
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('home-chat-back-button')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('home-chat-input-bar')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey<String>('home-action-chat')));
    await tester.pumpAndSettle();

    expect(find.text('sent message'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey<String>('chat-input-message-field')),
          )
          .controller!
          .text,
      'draft text',
    );
  });

  testWidgets('stays stable on narrow screens', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 690);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HomeScreen(onSettingsTap: nullHandler)),
      ),
    );
    await tester.pumpAndSettle();

    final initialStageSize = tester.getSize(
      find.byKey(const ValueKey<String>('home-room-stage-shell')),
    );
    expect(initialStageSize.width, greaterThan(288));

    await tester.tap(find.byKey(const ValueKey<String>('home-action-chat')));
    await tester.pumpAndSettle();

    final chatStageSize = tester.getSize(
      find.byKey(const ValueKey<String>('home-room-stage-shell')),
    );
    expect(chatStageSize.width, closeTo(initialStageSize.width, 0.1));

    await tester.enterText(
      find.byKey(const ValueKey<String>('chat-input-message-field')),
      '狭い画面でも確認するよ。',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('chat-input-send')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey<String>('home-message-layer')),
      findsOneWidget,
    );
  });
}

void nullHandler() {}
