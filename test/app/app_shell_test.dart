import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdgoc_2026_prototype/app/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('starts on HOME without the bottom dock', (
    WidgetTester tester,
  ) async {
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
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('home-diary-entry')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('diary-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('diary-back-button')), findsOneWidget);
  });

  testWidgets('keeps immersive HOME back navigation for chat mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('home-action-chat')));
    await tester.pumpAndSettle();

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
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('home-settings-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('settings-screen')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('settings-back-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('home-diary-entry')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('diary-settings-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('settings-screen')), findsOneWidget);
  });
}
