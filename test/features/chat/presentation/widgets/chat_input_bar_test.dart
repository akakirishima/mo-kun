import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdgoc_2026_prototype/features/chat/presentation/widgets/chat_input_bar.dart';

void main() {
  testWidgets('is editable and toggles send affordance from input state', (
    WidgetTester tester,
  ) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return ChatInputBar(
                controller: controller,
                sendEnabled: controller.text.trim().isNotEmpty,
                onChanged: (_) => setState(() {}),
                onSendTap: () {},
              );
            },
          ),
        ),
      ),
    );

    final initialSendButton = tester.widget<IconButton>(
      find.byKey(const ValueKey<String>('chat-input-send')),
    );
    expect(initialSendButton.onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey<String>('chat-input-message-field')),
      'こんにちは',
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<IconButton>(
            find.byKey(const ValueKey<String>('chat-input-send')),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('delegates camera and image taps', (WidgetTester tester) async {
    var cameraTapCount = 0;
    var imageTapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatInputBar(
            onCameraTap: () => cameraTapCount += 1,
            onImageTap: () => imageTapCount += 1,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('chat-input-camera')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('chat-input-image')));
    await tester.pumpAndSettle();

    expect(cameraTapCount, 1);
    expect(imageTapCount, 1);
  });
}
