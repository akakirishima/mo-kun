import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdgoc_2026_prototype/features/image/presentation/image_screen.dart';

import '../../../test_support/fake_app.dart';

void main() {
  testWidgets('renders the latest image status and history list', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapWithTestApp(child: ImageScreen(onSettingsTap: () {})),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('image-screen')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('image-latest-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('image-latest-status')),
      findsOneWidget,
    );
    expect(find.text('更新済み'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('image-history-header')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('image-history-item-0')),
      findsOneWidget,
    );
  });

  testWidgets('floating action button shows placeholder feedback', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapWithTestApp(child: ImageScreen(onSettingsTap: () {})),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('image-post-fab')));
    await tester.pumpAndSettle();

    expect(find.text('画像の手動再生成は backend 実装後に追加します'), findsOneWidget);
  });
}
