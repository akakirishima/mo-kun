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
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('starts on HOME without the bottom dock', (
    WidgetTester tester,
  ) async {
    configureViewport(tester);
    registerViewportTearDown(tester);
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('app-navigation-bar')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('home-room-stage')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('home-diary-entry')),
      findsOneWidget,
    );
  });

  testWidgets('opens Diary from the HOME entry card', (
    WidgetTester tester,
  ) async {
    configureViewport(tester);
    registerViewportTearDown(tester);
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    await tapVisible(
      tester,
      find.byKey(const ValueKey<String>('home-diary-entry')),
    );

    expect(find.byKey(const ValueKey<String>('diary-screen')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('diary-back-button')),
      findsOneWidget,
    );
  });

  testWidgets('keeps immersive HOME back navigation for chat mode', (
    WidgetTester tester,
  ) async {
    configureViewport(tester);
    registerViewportTearDown(tester);
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    await tapVisible(
      tester,
      find.byKey(const ValueKey<String>('home-action-chat')),
    );

    expect(
      find.byKey(const ValueKey<String>('home-chat-back-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('app-navigation-bar')),
      findsNothing,
    );
  });

  testWidgets('opens settings from HOME and Diary', (
    WidgetTester tester,
  ) async {
    configureViewport(tester);
    registerViewportTearDown(tester);
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    await tapVisible(
      tester,
      find.byKey(const ValueKey<String>('home-settings-button')),
    );
    expect(
      find.byKey(const ValueKey<String>('settings-screen')),
      findsOneWidget,
    );
    await tapVisible(
      tester,
      find.byKey(const ValueKey<String>('settings-back-button')),
    );

    await tapVisible(
      tester,
      find.byKey(const ValueKey<String>('home-diary-entry')),
    );
    await tapVisible(
      tester,
      find.byKey(const ValueKey<String>('diary-settings-button')),
    );
    expect(
      find.byKey(const ValueKey<String>('settings-screen')),
      findsOneWidget,
    );
  });
}
