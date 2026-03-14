import 'package:flutter_test/flutter_test.dart';

import 'package:gdgoc_2026_prototype/main.dart';

void main() {
  testWidgets('bootstrap screen renders setup checklist', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('GDGoC 2026 Prototype'), findsOneWidget);
    expect(find.text('Bootstrap checklist'), findsOneWidget);
    expect(find.text('Flutter 3.41.2 stable'), findsOneWidget);
  });
}
