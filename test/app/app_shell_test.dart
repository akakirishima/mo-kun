import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdgoc_2026_prototype/app/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  void configureViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1600, 3200);
    tester.view.devicePixelRatio = 2.0;
  }

  void registerViewportTearDown(WidgetTester tester) {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewPadding);
    addTearDown(tester.view.resetPadding);
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder, warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  Future<void> waitForDiaryTeaser(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 900));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 25));
      if (find
          .byKey(const ValueKey<String>('diary-cover-turn-teaser'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }
  }

  testWidgets('starts on HOME with the bottom dock visible', (
    WidgetTester tester,
  ) async {
    configureViewport(tester);
    registerViewportTearDown(tester);
    await tester.pumpWidget(const App(enableDiaryCoverTurnTeaser: false));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('app-navigation-bar')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('app-navigation-dock')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('home-room-stage')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('home-talk-button')),
      findsOneWidget,
    );
  });

  testWidgets('switches between Home, Chat, Diary, and Settings tabs', (
    WidgetTester tester,
  ) async {
    configureViewport(tester);
    registerViewportTearDown(tester);
    await tester.pumpWidget(const App(enableDiaryCoverTurnTeaser: false));
    await tester.pumpAndSettle();

    await tapVisible(tester, find.byKey(const ValueKey<String>('nav-chat')));
    expect(find.byKey(const ValueKey<String>('chat-screen')), findsOneWidget);

    await tapVisible(tester, find.byKey(const ValueKey<String>('nav-diary')));
    expect(find.byKey(const ValueKey<String>('diary-screen')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('diary-back-button')),
      findsNothing,
    );

    await tapVisible(
      tester,
      find.byKey(const ValueKey<String>('nav-settings')),
    );
    expect(
      find.byKey(const ValueKey<String>('settings-screen')),
      findsOneWidget,
    );

    await tapVisible(tester, find.byKey(const ValueKey<String>('nav-home')));
    expect(
      find.byKey(const ValueKey<String>('home-talk-button')),
      findsOneWidget,
    );
  });

  testWidgets('opens Image from Settings', (WidgetTester tester) async {
    configureViewport(tester);
    registerViewportTearDown(tester);
    await tester.pumpWidget(const App(enableDiaryCoverTurnTeaser: false));
    await tester.pumpAndSettle();

    await tapVisible(
      tester,
      find.byKey(const ValueKey<String>('nav-settings')),
    );
    await tapVisible(
      tester,
      find.byKey(const ValueKey<String>('settings-item-image')),
    );

    expect(find.byKey(const ValueKey<String>('image-screen')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('image-back-button')),
      findsOneWidget,
    );
  });

  testWidgets('keeps the diary cover just above the bottom dock', (
    WidgetTester tester,
  ) async {
    configureViewport(tester);
    registerViewportTearDown(tester);
    await tester.pumpWidget(const App(enableDiaryCoverTurnTeaser: false));
    await tester.pumpAndSettle();

    await tapVisible(tester, find.byKey(const ValueKey<String>('nav-diary')));

    final dockRect = tester.getRect(
      find.byKey(const ValueKey<String>('app-navigation-dock')),
    );
    final artboardRect = tester.getRect(
      find.byKey(const ValueKey<String>('diary-cover-artboard')),
    );
    final gap = dockRect.top - artboardRect.bottom;

    expect(gap, moreOrLessEquals(12.0, epsilon: 2.0));
  });

  testWidgets('keeps the diary cover above the dock with bottom safe area', (
    WidgetTester tester,
  ) async {
    configureViewport(tester);
    registerViewportTearDown(tester);
    tester.view.viewPadding = const FakeViewPadding(
      left: 0,
      top: 0,
      right: 0,
      bottom: 34,
    );
    tester.view.padding = const FakeViewPadding(
      left: 0,
      top: 0,
      right: 0,
      bottom: 34,
    );
    await tester.pumpWidget(const App(enableDiaryCoverTurnTeaser: false));
    await tester.pumpAndSettle();

    await tapVisible(tester, find.byKey(const ValueKey<String>('nav-diary')));

    final dockRect = tester.getRect(
      find.byKey(const ValueKey<String>('app-navigation-dock')),
    );
    final artboardRect = tester.getRect(
      find.byKey(const ValueKey<String>('diary-cover-artboard')),
    );
    final gap = dockRect.top - artboardRect.bottom;

    expect(gap, greaterThanOrEqualTo(12.0));
  });

  testWidgets('plays the diary teaser when the diary tab opens', (
    WidgetTester tester,
  ) async {
    configureViewport(tester);
    registerViewportTearDown(tester);
    await tester.pumpWidget(const App(enableDiaryCoverTurnTeaser: true));
    await tester.pumpAndSettle();

    await tapVisible(tester, find.byKey(const ValueKey<String>('nav-diary')));

    expect(
      find.byKey(const ValueKey<String>('diary-cover-turn-teaser')),
      findsNothing,
    );

    await waitForDiaryTeaser(tester);

    expect(
      find.byKey(const ValueKey<String>('diary-cover-turn-teaser')),
      findsOneWidget,
    );
  });

  testWidgets('replays the diary teaser when returning to the cover tab', (
    WidgetTester tester,
  ) async {
    configureViewport(tester);
    registerViewportTearDown(tester);
    await tester.pumpWidget(const App(enableDiaryCoverTurnTeaser: true));
    await tester.pumpAndSettle();

    await tapVisible(tester, find.byKey(const ValueKey<String>('nav-diary')));
    await waitForDiaryTeaser(tester);
    expect(
      find.byKey(const ValueKey<String>('diary-cover-turn-teaser')),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 800));
    await tapVisible(tester, find.byKey(const ValueKey<String>('nav-chat')));
    await tapVisible(tester, find.byKey(const ValueKey<String>('nav-diary')));

    expect(
      find.byKey(const ValueKey<String>('diary-cover-turn-teaser')),
      findsNothing,
    );

    await waitForDiaryTeaser(tester);

    expect(
      find.byKey(const ValueKey<String>('diary-cover-turn-teaser')),
      findsOneWidget,
    );
  });

  testWidgets('keeps the first diary entry content close to the dock', (
    WidgetTester tester,
  ) async {
    configureViewport(tester);
    registerViewportTearDown(tester);
    await tester.pumpWidget(const App(enableDiaryCoverTurnTeaser: false));
    await tester.pumpAndSettle();

    await tapVisible(tester, find.byKey(const ValueKey<String>('nav-diary')));
    await tester.drag(
      find.byKey(const ValueKey<String>('diary-book-page-view')),
      const Offset(-420, 0),
    );
    await tester.pumpAndSettle();

    final dockRect = tester.getRect(
      find.byKey(const ValueKey<String>('app-navigation-dock')),
    );
    final writingPaperRect = tester.getRect(
      find.byKey(
        ValueKey<String>('diary-entry-writing-paper-${DateTime.now().day}'),
      ),
    );
    final gap = dockRect.top - writingPaperRect.bottom;

    expect(gap, inInclusiveRange(12.0, 40.0));
  });

  testWidgets('does not replay the teaser when returning on an entry page', (
    WidgetTester tester,
  ) async {
    configureViewport(tester);
    registerViewportTearDown(tester);
    await tester.pumpWidget(const App(enableDiaryCoverTurnTeaser: true));
    await tester.pumpAndSettle();

    await tapVisible(tester, find.byKey(const ValueKey<String>('nav-diary')));
    await tester.drag(
      find.byKey(const ValueKey<String>('diary-book-page-view')),
      const Offset(-420, 0),
    );
    await tester.pumpAndSettle();

    await tapVisible(tester, find.byKey(const ValueKey<String>('nav-chat')));
    await tapVisible(tester, find.byKey(const ValueKey<String>('nav-diary')));
    await tester.pump(const Duration(seconds: 5));

    expect(
      find.byKey(const ValueKey<String>('diary-cover-turn-teaser')),
      findsNothing,
    );
  });
}
