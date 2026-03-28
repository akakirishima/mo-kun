import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdgoc_2026_prototype/core/app/app_providers.dart';
import 'package:gdgoc_2026_prototype/core/theme/app_theme.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_controller.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';
import 'package:gdgoc_2026_prototype/features/onboarding/presentation/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../test_support/fake_app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Widget buildOnboardingApp() {
    final controller = AppearanceController();
    return ProviderScope(
      overrides: [appRepositoryProvider.overrideWithValue(buildFakeRepository())],
      child: AppearanceScope(
        controller: controller,
        child: MaterialApp(
          theme: AppTheme.light(controller.palette),
          home: const OnboardingScreen(),
        ),
      ),
    );
  }

  testWidgets('renders theme color dropdown without overflow text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildOnboardingApp());

    expect(find.text('Blossom'), findsOneWidget);
    expect(find.text('やわらかいピンクとクリーム'), findsOneWidget);
  });

  testWidgets('updates theme description when another preset is selected', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildOnboardingApp());

    await tester.tap(find.text('Blossom'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forest').last);
    await tester.pumpAndSettle();

    expect(find.text('Forest'), findsOneWidget);
    expect(find.text('落ち着いたグリーンとセージ'), findsOneWidget);
  });
}
