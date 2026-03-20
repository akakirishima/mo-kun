import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdgoc_2026_prototype/app/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  void configureViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1600, 3200);
    tester.view.devicePixelRatio = 2.0;
  }

  void registerViewportTearDown(WidgetTester tester) {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder, warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  testWidgets('starts on HOME with the bottom dock visible', (
    WidgetTester tester,
  ) async {
    configureViewport(tester);
    registerViewportTearDown(tester);
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('app-navigation-bar')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('home-room-stage')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('home-talk-button')), findsOneWidget);
  });

  testWidgets('switches between Home, Chat, Diary, and Settings tabs', (
    WidgetTester tester,
  ) async {
    configureViewport(tester);
    registerViewportTearDown(tester);
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    await tapVisible(tester, find.byKey(const ValueKey<String>('nav-chat')));
    expect(find.byKey(const ValueKey<String>('chat-screen')), findsOneWidget);

    await tapVisible(tester, find.byKey(const ValueKey<String>('nav-diary')));
    expect(find.byKey(const ValueKey<String>('diary-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('diary-back-button')), findsNothing);

    await tapVisible(tester, find.byKey(const ValueKey<String>('nav-settings')));
    expect(
      find.byKey(const ValueKey<String>('settings-screen')),
      findsOneWidget,
    );

    await tapVisible(tester, find.byKey(const ValueKey<String>('nav-home')));
    expect(find.byKey(const ValueKey<String>('home-talk-button')), findsOneWidget);
  });

  testWidgets('opens Image from Settings', (WidgetTester tester) async {
    configureViewport(tester);
    registerViewportTearDown(tester);
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    await tapVisible(tester, find.byKey(const ValueKey<String>('nav-settings')));
    await tapVisible(
      tester,
      find.byKey(const ValueKey<String>('settings-item-image')),
    );

    expect(find.byKey(const ValueKey<String>('image-screen')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('image-back-button')),
      findsOneWidget,
    );
  });
}
