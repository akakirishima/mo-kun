import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdgoc_2026_prototype/app/app.dart';
import 'package:gdgoc_2026_prototype/app/shell/app_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Icon slotIcon(WidgetTester tester, AppTab tab) {
    return tester.widget<Icon>(
      find.byKey(ValueKey<String>('nav-slot-icon-${tab.name}')),
    );
  }

  testWidgets('starts on Home and shows four navigation destinations', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const App());
    expect(
      find.byKey(const ValueKey<String>('app-navigation-bar')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('app-page-view')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('nav-home')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('nav-chat')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('nav-diary')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('nav-image')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('nav-slot-icon-home')),
      findsOneWidget,
    );
    expect(slotIcon(tester, AppTab.home).icon, AppTab.home.selectedIcon);
    expect(find.byKey(const ValueKey<String>('nav-label-chat')), findsNothing);
    expect(find.byKey(const ValueKey<String>('nav-label-diary')), findsNothing);
    expect(find.byKey(const ValueKey<String>('nav-label-image')), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('home-room-stage')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('home-transcript-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('home-settings-button')),
      findsOneWidget,
    );
  });

  testWidgets('switches tabs from the bottom navigation bar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const App());

    await tester.tap(find.byKey(const ValueKey<String>('nav-chat')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('chat-top-bar')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('chat-input-bar')),
      findsOneWidget,
    );
    expect(slotIcon(tester, AppTab.chat).icon, AppTab.chat.selectedIcon);
    expect(slotIcon(tester, AppTab.home).icon, AppTab.home.icon);

    await tester.tap(find.byKey(const ValueKey<String>('nav-diary')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('diary-screen')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('diary-cover-page')),
      findsOneWidget,
    );
    expect(slotIcon(tester, AppTab.diary).icon, AppTab.diary.selectedIcon);

    await tester.tap(find.byKey(const ValueKey<String>('nav-image')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('image-highlight-row')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('image-post-fab')),
      findsOneWidget,
    );
    expect(slotIcon(tester, AppTab.image).icon, AppTab.image.selectedIcon);

    await tester.tap(find.byKey(const ValueKey<String>('nav-home')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('home-room-stage')),
      findsOneWidget,
    );
  });

  testWidgets('swipes between pages and keeps the dock in sync', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const App());

    await tester.drag(
      find.byKey(const ValueKey<String>('app-page-view')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('chat-top-bar')), findsOneWidget);
    expect(slotIcon(tester, AppTab.chat).icon, AppTab.chat.selectedIcon);
    expect(slotIcon(tester, AppTab.home).icon, AppTab.home.icon);
  });

  testWidgets('drags active pill and switches page only after release', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const App());

    final handle = find.byKey(
      const ValueKey<String>('glass-dock-active-pill-gesture'),
    );
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await gesture.moveBy(const Offset(120, 0));
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.moveBy(const Offset(120, 0));
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.moveBy(const Offset(120, 0));
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('home-room-stage')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('chat-top-bar')), findsNothing);

    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('chat-top-bar')), findsOneWidget);
    expect(slotIcon(tester, AppTab.chat).icon, AppTab.chat.selectedIcon);
  });

  testWidgets(
    'updates Home transcript from the talk button without switching tabs',
    (WidgetTester tester) async {
      await tester.pumpWidget(const App());

      expect(
        find.byKey(const ValueKey<String>('nav-slot-icon-home')),
        findsOneWidget,
      );
      expect(slotIcon(tester, AppTab.home).icon, AppTab.home.selectedIcon);
      expect(find.textContaining('ここに Mori の文字起こしが残るよ。'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('home-talk-button')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('home-talk-button')));
      await tester.pumpAndSettle();

      expect(slotIcon(tester, AppTab.home).icon, AppTab.home.selectedIcon);
      expect(find.textContaining('うん、ちゃんと聞こえてるよ。'), findsOneWidget);
    },
  );

  testWidgets('chat phone actions return Home and update transcript', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const App());

    await tester.tap(find.byKey(const ValueKey<String>('nav-chat')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('chat-top-phone')));
    await tester.pumpAndSettle();

    expect(slotIcon(tester, AppTab.home).icon, AppTab.home.selectedIcon);
    expect(find.textContaining('うん、ちゃんと聞こえてるよ。'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('nav-chat')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('chat-input-phone')));
    await tester.pumpAndSettle();

    expect(slotIcon(tester, AppTab.home).icon, AppTab.home.selectedIcon);
    expect(find.textContaining('今日あったことを、ゆっくり聞かせて。'), findsOneWidget);
  });

  testWidgets('opens and closes settings from every tab', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const App());

    await tester.tap(
      find.byKey(const ValueKey<String>('home-settings-button')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('settings-screen')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('settings-item-appearance')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('appearance-settings-screen')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('appearance-settings-back-button')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('settings-screen')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('settings-back-button')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('home-room-stage')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey<String>('nav-chat')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('chat-settings-button')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('settings-screen')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('settings-back-button')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('chat-top-bar')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('nav-diary')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('diary-settings-button')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('settings-screen')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('settings-back-button')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('diary-screen')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('nav-image')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('image-settings-button')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('settings-screen')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('settings-back-button')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('image-screen')), findsOneWidget);
  });

  testWidgets('diary horizontal drag turns pages without switching tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const App());

    await tester.tap(find.byKey(const ValueKey<String>('nav-diary')));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey<String>('diary-book-page-view')),
      const Offset(-420, 0),
    );
    await tester.pumpAndSettle();

    expect(slotIcon(tester, AppTab.diary).icon, AppTab.diary.selectedIcon);
    expect(
      find.byKey(const ValueKey<String>('diary-entry-page-1')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('chat-top-bar')), findsNothing);
  });

  testWidgets(
    'image highlight row keeps horizontal drag inside the image tab',
    (WidgetTester tester) async {
      await tester.pumpWidget(const App());

      await tester.tap(find.byKey(const ValueKey<String>('nav-image')));
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(const ValueKey<String>('image-highlight-row')),
        const Offset(-140, 0),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('nav-slot-icon-image')),
        findsOneWidget,
      );
      expect(slotIcon(tester, AppTab.image).icon, AppTab.image.selectedIcon);
      expect(
        find.byKey(const ValueKey<String>('image-highlight-row')),
        findsOneWidget,
      );
    },
  );
}
