import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdgoc_2026_prototype/core/app/app_repository.dart';
import 'package:gdgoc_2026_prototype/core/app/app_providers.dart';
import 'package:gdgoc_2026_prototype/core/theme/app_theme.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_controller.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';
import 'package:gdgoc_2026_prototype/features/settings/presentation/settings_screen.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../test_support/fake_app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Widget buildScopedSettingsApp({AppRepository? repository}) {
    final controller = AppearanceController();
    return ProviderScope(
      overrides: [
        appRepositoryProvider.overrideWithValue(
          repository ?? buildFakeRepository(),
        ),
      ],
      child: AppearanceScope(
        controller: controller,
        child: MaterialApp(
          theme: AppTheme.light(controller.palette),
          home: const SettingsScreen(),
        ),
      ),
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
      findsNothing,
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
    expect(
      find.byKey(const ValueKey<String>('settings-item-home-background')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('settings-item-image')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('settings-item-voice')),
      findsOneWidget,
    );
  });

  testWidgets('opens the appearance settings screen from デザイン', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildScopedSettingsApp());

    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('settings-item-appearance')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('settings-item-appearance')),
      warnIfMissed: false,
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

    expect(
      find.byKey(const ValueKey<String>('settings-screen')),
      findsOneWidget,
    );
  });

  testWidgets('opens the profile settings screen from プロフィール', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildScopedSettingsApp());

    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('settings-item-profile')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('settings-item-profile')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('profile-settings-screen')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('profile-settings-display-name')),
      findsOneWidget,
    );
  });

  testWidgets('opens the image screen from Image', (WidgetTester tester) async {
    await tester.pumpWidget(buildScopedSettingsApp());

    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('settings-item-image')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('settings-item-image')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('image-screen')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('image-back-button')),
      findsOneWidget,
    );
  });

  testWidgets('opens the home background settings screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildScopedSettingsApp());

    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('settings-item-home-background')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('settings-item-home-background')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('home-background-settings-screen')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('home-background-preview-image')),
      findsOneWidget,
    );
  });

  testWidgets('changes the home background preset from settings', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildScopedSettingsApp(repository: buildFakeRepository()),
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('settings-item-home-background')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('settings-item-home-background')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    final previewCard = find.byKey(
      const ValueKey<String>('home-background-preview-card'),
    );
    expect(
      find.descendant(of: previewCard, matching: find.text('夕焼け')),
      findsOneWidget,
    );

    final nightPreset = find.byKey(
      const ValueKey<String>('home-background-preset-yoru'),
    );
    await tester.ensureVisible(nightPreset);
    await tester.tap(nightPreset, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: previewCard, matching: find.text('夜空')),
      findsOneWidget,
    );
  });

  testWidgets('opens the character settings screen from AI / キャラクター', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildScopedSettingsApp());

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('settings-item-ai')),
      120,
    );
    final aiTile = tester.widget<NesPressable>(
      find.byKey(const ValueKey<String>('settings-item-ai')),
    );
    aiTile.onPress?.call();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('character-settings-screen')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('character-settings-name')),
      findsOneWidget,
    );
  });

  testWidgets('opens the voice settings screen from AI音声', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildScopedSettingsApp());

    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('settings-item-voice')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('settings-item-voice')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('voice-settings-screen')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('voice-option-Kore')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('voice-settings-save-button')),
      findsOneWidget,
    );
  });
}
