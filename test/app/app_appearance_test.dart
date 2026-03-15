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

  Color scaffoldColor(WidgetTester tester, String keyName) {
    final scaffold = tester.widget<Scaffold>(
      find.byKey(ValueKey<String>(keyName)),
    );
    return scaffold.backgroundColor!;
  }

  LinearGradient decoratedGradient(WidgetTester tester, String keyName) {
    final box = tester.widget<DecoratedBox>(
      find.byKey(ValueKey<String>(keyName)),
    );
    final decoration = box.decoration as BoxDecoration;
    return decoration.gradient! as LinearGradient;
  }

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('restores the saved appearance preset on startup', (
    WidgetTester tester,
  ) async {
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
    'default blossom preset is applied across room diary image and settings',
    (WidgetTester tester) async {
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

      await tester.tap(find.byKey(const ValueKey<String>('nav-diary')));
      await tester.pumpAndSettle();
      expect(
        backgroundGradient(tester, 'diary-background').colors.first,
        const Color(0xFFFFEEF5),
      );

      await tester.tap(find.byKey(const ValueKey<String>('nav-image')));
      await tester.pumpAndSettle();
      expect(scaffoldColor(tester, 'image-scaffold'), const Color(0xFFFFFAFD));

      expect(
        decoratedGradient(tester, 'image-highlight-gradient-meal').colors.first,
        const Color(0xFFFFD8E6),
      );
      expect(
        decoratedGradient(
          tester,
          'image-ai-select-gradient-sunset',
        ).colors.first,
        const Color(0xFFE887AF),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('image-settings-button')),
      );
      await tester.pumpAndSettle();
      expect(
        backgroundGradient(tester, 'settings-background').colors.first,
        const Color(0xFFFFF4FA),
      );
    },
  );

  testWidgets('opens appearance settings and applies a new preset', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('home-settings-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('settings-item-appearance')),
    );
    await tester.pumpAndSettle();

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

    await tester.tap(
      find.byKey(const ValueKey<String>('appearance-preset-forest')),
    );
    await tester.pumpAndSettle();

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

    await tester.tap(
      find.byKey(const ValueKey<String>('appearance-settings-back-button')),
    );
    await tester.pumpAndSettle();
    expect(
      backgroundGradient(tester, 'settings-background').colors.first,
      const Color(0xFFF5FAF4),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('settings-back-button')),
    );
    await tester.pumpAndSettle();
    expect(
      backgroundGradient(tester, 'home-background').colors.first,
      const Color(0xFFE5F3E8),
    );

    await tester.tap(find.byKey(const ValueKey<String>('nav-diary')));
    await tester.pumpAndSettle();
    expect(
      backgroundGradient(tester, 'diary-background').colors.first,
      const Color(0xFFF2F8EF),
    );

    await tester.tap(find.byKey(const ValueKey<String>('nav-image')));
    await tester.pumpAndSettle();
    expect(scaffoldColor(tester, 'image-scaffold'), const Color(0xFFF7FBF6));
    expect(
      decoratedGradient(tester, 'image-highlight-gradient-meal').colors.first,
      const Color(0xFFCFE8CE),
    );
    expect(
      decoratedGradient(tester, 'image-ai-select-gradient-sunset').colors.first,
      const Color(0xFF56825A),
    );

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString(AppearanceController.storageKey), 'forest');
  });
}
