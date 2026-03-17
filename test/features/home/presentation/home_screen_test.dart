import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdgoc_2026_prototype/features/home/presentation/home_screen.dart';
import 'package:image_picker/image_picker.dart';

import '../../../test_support/fake_app.dart';

void main() {
  testWidgets('renders the Mori card, room stage, and action buttons', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapWithTestApp(child: HomeScreen(onSettingsTap: nullHandler)),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('home-mori-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('home-room-stage')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('home-action-bar')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('home-action-chat')),
      findsOneWidget,
    );
  });

  testWidgets('shows assistant history and sends a new pending message', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapWithTestApp(child: HomeScreen(onSettingsTap: nullHandler)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('home-action-chat')));
    await tester.pumpAndSettle();

    expect(find.textContaining('昨日の積み上げ'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey<String>('chat-input-message-field')),
      '今日は朝に散歩した',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('chat-input-send')));
    await tester.pumpAndSettle();
    expect(find.text('今日は朝に散歩した'), findsWidgets);
    expect(find.textContaining('反映しておくね'), findsOneWidget);
    final userTopLeft = tester.getTopLeft(
      find.byKey(const ValueKey<String>('home-user-bubble-0')).last,
    );
    final assistantTopLeft = tester.getTopLeft(
      find.byKey(const ValueKey<String>('home-assistant-bubble-1')),
    );
    expect(userTopLeft.dy, lessThan(assistantTopLeft.dy));
  });

  testWidgets('shows pending preview after gallery selection', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapWithTestApp(
        child: HomeScreen(
          onSettingsTap: nullHandler,
          pickImage: (source) async {
            expect(source, ImageSource.gallery);
            return XFile('/tmp/home-gallery.png');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('home-action-chat')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('chat-input-image')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('home-chat-pending-preview')),
      findsOneWidget,
    );
    expect(find.text('home-gallery.png'), findsOneWidget);
  });

  testWidgets('preserves draft text and sent messages across back navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapWithTestApp(child: HomeScreen(onSettingsTap: nullHandler)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('home-action-chat')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('chat-input-message-field')),
      'draft text',
    );
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey<String>('home-chat-back-button')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('home-action-chat')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey<String>('chat-input-message-field')),
          )
          .controller!
          .text,
      'draft text',
    );
  });
}

void nullHandler() {}
