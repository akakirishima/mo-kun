import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdgoc_2026_prototype/app/app.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Color scaffoldBackgroundColor(WidgetTester tester) {
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    return app.theme!.scaffoldBackgroundColor;
  }

  LinearGradient backgroundGradient(WidgetTester tester, String keyName) {
    final box = tester.widget<DecoratedBox>(
      find.byKey(ValueKey<String>(keyName)),
    );
    final decoration = box.decoration as BoxDecoration;
    return decoration.gradient! as LinearGradient;
  }

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

  testWidgets('restores the saved appearance preset on startup', (
    WidgetTester tester,
  ) async {
    configureViewport(tester);
    registerViewportTearDown(tester);
    SharedPreferences.setMockInitialValues(<String, Object>{
      AppearanceController.storageKey: 'sky',
    });

    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(scaffoldBackgroundColor(tester), const Color(0xFFF5FAFF));
    expect(
      backgroundGradient(tester, 'home-background').colors.first,
      const Color(0xFFDCEEFF),
    );
  });

  testWidgets(
    'default blossom preset is applied across home diary and settings',
    (WidgetTester tester) async {
      configureViewport(tester);
      registerViewportTearDown(tester);
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();

      expect(
        backgroundGradient(tester, 'home-background').colors.first,
        const Color(0xFFFFE3EE),
      );
      expect(
        find.byKey(const ValueKey<String>('home-action-chat')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('home-chat-input-bar')),
        findsNothing,
      );

      await tapVisible(
        tester,
        find.byKey(const ValueKey<String>('home-diary-entry')),
      );
      expect(
        backgroundGradient(tester, 'diary-background').colors.first,
        const Color(0xFFFFEEF5),
      );

      await tapVisible(
        tester,
        find.byKey(const ValueKey<String>('diary-back-button')),
      );
      await tapVisible(
        tester,
        find.byKey(const ValueKey<String>('home-settings-button')),
      );
      expect(
        backgroundGradient(tester, 'settings-background').colors.first,
        const Color(0xFFFFF4FA),
      );
    },
  );

  testWidgets('opens appearance settings and applies a new preset', (
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
    await tapVisible(
      tester,
      find.byKey(const ValueKey<String>('settings-item-appearance')),
    );

    expect(
      find.byKey(const ValueKey<String>('appearance-settings-screen')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('appearance-preview-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('appearance-preset-blossom')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('appearance-preset-sky')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('appearance-preset-forest')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('appearance-preset-sunset')),
      findsOneWidget,
    );

    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(const ValueKey<String>('appearance-selected-blossom')),
          )
          .opacity,
      1,
    );

    await tapVisible(
      tester,
      find.byKey(const ValueKey<String>('appearance-preset-forest')),
    );

    expect(scaffoldBackgroundColor(tester), const Color(0xFFF6FBF6));
    expect(
      backgroundGradient(tester, 'appearance-settings-background').colors.first,
      const Color(0xFFF5FAF4),
    );
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(const ValueKey<String>('appearance-selected-forest')),
          )
          .opacity,
      1,
    );
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(const ValueKey<String>('appearance-selected-blossom')),
          )
          .opacity,
      0,
    );

    await tapVisible(
      tester,
      find.byKey(const ValueKey<String>('appearance-settings-back-button')),
    );
    expect(
      backgroundGradient(tester, 'settings-background').colors.first,
      const Color(0xFFF5FAF4),
    );
    await tapVisible(
      tester,
      find.byKey(const ValueKey<String>('settings-back-button')),
    );
    expect(
      backgroundGradient(tester, 'home-background').colors.first,
      const Color(0xFFE5F3E8),
    );

    await tapVisible(
      tester,
      find.byKey(const ValueKey<String>('home-diary-entry')),
    );
    expect(
      backgroundGradient(tester, 'diary-background').colors.first,
      const Color(0xFFF2F8EF),
    );

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString(AppearanceController.storageKey), 'forest');
  });
}
