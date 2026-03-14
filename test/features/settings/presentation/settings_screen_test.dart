import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_controller.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';
import 'package:gdgoc_2026_prototype/features/settings/presentation/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Widget buildScopedSettingsApp() {
    final controller = AppearanceController();
    return AppearanceScope(
      controller: controller,
      child: const MaterialApp(home: SettingsScreen()),
    );
  }

  testWidgets('renders the shared settings screen and placeholder items', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildScopedSettingsApp());

    expect(
      find.byKey(const ValueKey<String>('settings-screen')),
      findsOneWidget,
    );
    expect(find.text('Settings'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('settings-back-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('settings-item-profile')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('settings-item-notifications')),
      findsOneWidget,
    );
    expect(find.text('AI / キャラクター'), findsOneWidget);
  });

  testWidgets('opens the appearance settings screen from 表示', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildScopedSettingsApp());

    await tester.tap(
      find.byKey(const ValueKey<String>('settings-item-appearance')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('appearance-settings-screen')),
      findsOneWidget,
    );
    expect(find.text('表示'), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey<String>('appearance-settings-back-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('settings-screen')),
      findsOneWidget,
    );
  });
}
