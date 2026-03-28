import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdgoc_2026_prototype/core/app/app_models.dart';
import 'package:gdgoc_2026_prototype/core/app/fake_app_repository.dart';
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

  testWidgets('shows voice label for live voice messages', (
    WidgetTester tester,
  ) async {
    final repository = FakeAppRepository(
      initialSession: const AppSession(
        userId: 'test-user',
        needsOnboarding: false,
        characterId: 'test-character',
        threadId: 'test-thread',
      ),
      initialMessages: <ChatMessage>[
        ChatMessage(
          id: 'voice-user',
          role: ChatRole.user,
          text: '今日は音声で相談したい',
          createdAt: DateTime(2026, 3, 28, 3, 14),
          inputType: ChatInputType.voice,
          transport: ChatTransport.live,
        ),
        ChatMessage(
          id: 'voice-assistant',
          role: ChatRole.assistant,
          text: 'もちろん。ひとつずつ整理しよう。',
          createdAt: DateTime(2026, 3, 28, 3, 15),
          transport: ChatTransport.live,
        ),
      ],
    );

    await tester.pumpWidget(
      wrapWithTestApp(repository: repository, child: const ChatScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('VOICE'), findsNWidgets(2));
    expect(find.text('今日は音声で相談したい'), findsOneWidget);
    expect(find.text('もちろん。ひとつずつ整理しよう。'), findsOneWidget);
  });
}
