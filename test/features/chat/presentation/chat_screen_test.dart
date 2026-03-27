import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdgoc_2026_prototype/features/chat/presentation/chat_screen.dart';

import '../../../test_support/fake_app.dart';

void main() {
  testWidgets('does not show chat count in the header', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrapWithTestApp(child: const ChatScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Chat'), findsOneWidget);
    expect(find.textContaining('件'), findsNothing);
  });

  testWidgets('tapping outside the field dismisses keyboard focus', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrapWithTestApp(child: const ChatScreen()));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('chat-input-message-field')),
    );
    await tester.pumpAndSettle();

    final editableText = tester.widget<EditableText>(find.byType(EditableText));
    expect(editableText.focusNode.hasFocus, isTrue);

    await tester.tapAt(const Offset(24, 24));
    await tester.pumpAndSettle();

    expect(editableText.focusNode.hasFocus, isFalse);
  });
}
