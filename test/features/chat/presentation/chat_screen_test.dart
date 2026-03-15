import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdgoc_2026_prototype/features/chat/presentation/chat_screen.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  testWidgets('renders the LINE-like top bar, messages, and input actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatScreen(onStartHomeCallTap: () {}, onSettingsTap: () {}),
        ),
      ),
    );

    expect(find.byKey(const ValueKey<String>('chat-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('chat-top-bar')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('chat-top-search')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('chat-top-phone')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('chat-settings-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('chat-message-list')),
      findsOneWidget,
    );
    expect(find.text('Mori'), findsWidgets);
    expect(find.text('今日'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('chat-input-bar')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('chat-input-camera')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('chat-input-image')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('chat-input-message-field')),
      findsOneWidget,
    );
    expect(find.text('メッセージ'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('chat-input-mic')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('chat-input-send')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('chat-input-phone')),
      findsOneWidget,
    );
  });

  testWidgets(
    'shows the character avatar and keeps user messages right aligned',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatScreen(onStartHomeCallTap: () {}, onSettingsTap: () {}),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('chat-message-character-avatar')),
        findsOneWidget,
      );

      final userAlign = tester.widget<Align>(
        find.byKey(const ValueKey<String>('chat-message-user-align')),
      );
      final characterAlign = tester.widget<Align>(
        find.byKey(const ValueKey<String>('chat-message-character-align')),
      );

      expect(userAlign.alignment, Alignment.centerRight);
      expect(characterAlign.alignment, Alignment.centerLeft);
    },
  );

  testWidgets('does not overflow on a narrow screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 690);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatScreen(onStartHomeCallTap: () {}, onSettingsTap: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey<String>('chat-input-bar')),
      findsOneWidget,
    );
  });

  testWidgets('phone actions delegate to the Home talk shortcut', (
    WidgetTester tester,
  ) async {
    var phoneTapCount = 0;
    var didTapSettings = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatScreen(
            onStartHomeCallTap: () {
              phoneTapCount += 1;
            },
            onSettingsTap: () {
              didTapSettings = true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('chat-top-phone')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('chat-input-phone')));
    await tester.pumpAndSettle();

    expect(phoneTapCount, 2);

    await tester.tap(
      find.byKey(const ValueKey<String>('chat-settings-button')),
    );
    await tester.pumpAndSettle();

    expect(didTapSettings, isTrue);
  });

  testWidgets('shows a pending image preview after gallery selection', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatScreen(
            onStartHomeCallTap: () {},
            onSettingsTap: () {},
            pickImage: (source) async {
              expect(source, ImageSource.gallery);
              return XFile('/tmp/gallery-image.png');
            },
          ),
        ),
      ),
    );

    expect(
      tester
          .widget<IconButton>(
            find.byKey(const ValueKey<String>('chat-input-send')),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const ValueKey<String>('chat-input-image')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('chat-pending-preview')),
      findsOneWidget,
    );
    expect(find.text('gallery-image.png'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const ValueKey<String>('chat-input-send')),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('shows a pending image preview after camera capture', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatScreen(
            onStartHomeCallTap: () {},
            onSettingsTap: () {},
            pickImage: (source) async {
              expect(source, ImageSource.camera);
              return XFile('/tmp/camera-image.png');
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('chat-input-camera')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('chat-pending-preview')),
      findsOneWidget,
    );
    expect(find.text('camera-image.png'), findsOneWidget);
  });

  testWidgets('removing the pending preview disables send again', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatScreen(
            onStartHomeCallTap: () {},
            onSettingsTap: () {},
            pickImage: (_) async => XFile('/tmp/removable.png'),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('chat-input-image')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('chat-pending-preview-remove')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('chat-pending-preview')),
      findsNothing,
    );
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const ValueKey<String>('chat-input-send')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('sends an image message and keeps it right aligned', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatScreen(
            onStartHomeCallTap: () {},
            onSettingsTap: () {},
            pickImage: (_) async => XFile('/tmp/outgoing-image.png'),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('chat-input-image')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('chat-input-send')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('chat-pending-preview')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('chat-message-image-5')),
      findsOneWidget,
    );

    final imageMessageAlign = tester.widget<Align>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('chat-message-5')),
        matching: find.byType(Align),
      ),
    );
    expect(imageMessageAlign.alignment, Alignment.centerRight);
  });

  testWidgets('sends image and text as separate messages', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatScreen(
            onStartHomeCallTap: () {},
            onSettingsTap: () {},
            pickImage: (_) async => XFile('/tmp/paired-image.png'),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('chat-input-image')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('chat-input-message-field')),
      '画像も送るよ',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('chat-input-send')));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey<String>('chat-message-list')),
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('chat-message-image-5')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('chat-message-6')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('chat-message-6')),
        matching: find.byType(Text),
      ),
      findsWidgets,
    );
  });
}
