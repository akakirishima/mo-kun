import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdgoc_2026_prototype/app/app.dart';
import 'package:gdgoc_2026_prototype/app/shell/app_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Icon slotIcon(WidgetTester tester, AppTab tab) {
    return tester.widget<Icon>(
      find.byKey(ValueKey<String>('nav-slot-icon-${tab.name}')),
    );
  }

  testWidgets('starts on Room and shows three navigation destinations', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const App());

    expect(
      find.byKey(const ValueKey<String>('app-navigation-bar')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('app-page-view')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('nav-home')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('nav-diary')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('nav-image')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('nav-chat')), findsNothing);
    expect(slotIcon(tester, AppTab.home).icon, AppTab.home.selectedIcon);
    expect(
      find.byKey(const ValueKey<String>('home-room-stage')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('home-mori-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('home-action-chat')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('home-chat-input-bar')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('home-chat-back-button')),
      findsNothing,
    );
  });

  testWidgets('hides the app dock in immersive Home modes and restores it', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const App());

    await tester.tap(find.byKey(const ValueKey<String>('home-action-chat')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('app-navigation-bar')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('home-chat-back-button')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('home-chat-back-button')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('app-navigation-bar')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey<String>('home-action-phone')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('app-navigation-bar')),
      findsNothing,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('home-chat-back-button')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('app-navigation-bar')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey<String>('home-action-photo')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('app-navigation-bar')),
      findsNothing,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('home-chat-back-button')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('app-navigation-bar')),
      findsOneWidget,
    );
  });

  testWidgets('switches tabs from the bottom navigation bar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const App());

    await tester.tap(find.byKey(const ValueKey<String>('nav-diary')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('diary-screen')), findsOneWidget);
    expect(slotIcon(tester, AppTab.diary).icon, AppTab.diary.selectedIcon);

    await tester.tap(find.byKey(const ValueKey<String>('nav-image')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('image-highlight-row')),
      findsOneWidget,
    );
    expect(slotIcon(tester, AppTab.image).icon, AppTab.image.selectedIcon);

    await tester.tap(find.byKey(const ValueKey<String>('nav-home')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('home-room-stage')),
      findsOneWidget,
    );
  });

  testWidgets('swipes between pages and keeps the dock in sync', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const App());

    await tester.drag(
      find.byKey(const ValueKey<String>('app-page-view')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('diary-screen')), findsOneWidget);
    expect(slotIcon(tester, AppTab.diary).icon, AppTab.diary.selectedIcon);
    expect(slotIcon(tester, AppTab.home).icon, AppTab.home.icon);
  });

  testWidgets('drags active pill and switches page only after release', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const App());

    final handle = find.byKey(
      const ValueKey<String>('glass-dock-active-pill-gesture'),
    );
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await gesture.moveBy(const Offset(100, 0));
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.moveBy(const Offset(100, 0));
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.moveBy(const Offset(100, 0));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('home-room-stage')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('diary-screen')), findsNothing);

    await gesture.up();
    await tester.pumpAndSettle();

    expect(slotIcon(tester, AppTab.home).icon, AppTab.home.icon);
    expect(
      find
              .byKey(const ValueKey<String>('diary-screen'))
              .evaluate()
              .isNotEmpty ||
          find
              .byKey(const ValueKey<String>('image-highlight-row'))
              .evaluate()
              .isNotEmpty,
      isTrue,
    );
  });

  testWidgets('sends a message from the Room composer', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const App());

    await tester.tap(find.byKey(const ValueKey<String>('home-action-chat')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('app-navigation-bar')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('home-chat-back-button')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('home-action-bar')), findsNothing);

    final sendButton = tester.widget<IconButton>(
      find.byKey(const ValueKey<String>('chat-input-send')),
    );
    expect(sendButton.onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey<String>('chat-input-message-field')),
      'いまUIを整えてる。チャット画面をLINEっぽくしたい。',
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
    expect(find.text('いまUIを整えてる。チャット画面をLINEっぽくしたい。'), findsWidgets);
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

  testWidgets('opens and closes settings from every visible tab', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const App());

    await tester.tap(
      find.byKey(const ValueKey<String>('home-settings-button')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('settings-screen')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('settings-item-appearance')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('appearance-settings-screen')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('appearance-settings-back-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('settings-back-button')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('nav-diary')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('diary-settings-button')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('settings-screen')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('settings-back-button')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('nav-image')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('image-settings-button')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('settings-screen')),
      findsOneWidget,
    );
  });
}
