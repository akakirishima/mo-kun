import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdgoc_2026_prototype/app/shell/app_shell.dart';
import 'package:gdgoc_2026_prototype/app/shell/app_tab.dart';
import 'package:gdgoc_2026_prototype/core/theme/app_theme.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_controller.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';

void main() {
  testWidgets('matches the diary docs screenshot', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final appearanceController = AppearanceController();

    await tester.pumpWidget(
      AppearanceScope(
        controller: appearanceController,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(appearanceController.palette),
          home: const AppShell(initialTab: AppTab.diary),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('../../../../docs/ui/screenshots/diary.png'),
    );
  });
}
