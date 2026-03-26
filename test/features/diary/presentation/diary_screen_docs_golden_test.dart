import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/diary_screen.dart';

import '../../../test_support/fake_app.dart';

void main() {
  testWidgets('renders the diary docs surface without layout exceptions', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      wrapWithTestApp(child: const DiaryScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('diary-screen')), findsOneWidget);
  });
}
