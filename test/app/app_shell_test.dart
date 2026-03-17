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

  testWidgets(
    'starts on Room after bootstrap and shows three navigation destinations',
    (WidgetTester tester) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('app-navigation-bar')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey<String>('nav-home')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('nav-diary')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('nav-image')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('nav-chat')), findsNothing);
      expect(slotIcon(tester, AppTab.home).icon, AppTab.home.selectedIcon);
      expect(
        find.byKey(const ValueKey<String>('home-room-stage')),
        findsOneWidget,
      );
    },
  );

  testWidgets('switches tabs from the bottom navigation bar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('nav-diary')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('diary-screen')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('nav-image')));
    await tester.pumpAndSettle();
    expect(slotIcon(tester, AppTab.image).icon, AppTab.image.selectedIcon);
  });

  testWidgets('hides the app dock in immersive Home modes and restores it', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

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
  });

  testWidgets(
    'sends a message from the Room composer and shows assistant feedback',
    (WidgetTester tester) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('home-action-chat')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey<String>('chat-input-message-field')),
        '昨日は筋トレを頑張ったよ',
      );
      await tester.tap(find.byKey(const ValueKey<String>('chat-input-send')));

      await tester.pumpAndSettle();
      expect(find.text('昨日は筋トレを頑張ったよ'), findsWidgets);
    },
  );

  testWidgets('opens settings from every visible tab', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('home-settings-button')),
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
