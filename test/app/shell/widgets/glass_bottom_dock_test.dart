import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdgoc_2026_prototype/app/shell/app_tab.dart';
import 'package:gdgoc_2026_prototype/app/shell/widgets/glass_bottom_dock.dart';

void main() {
  Icon slotIcon(WidgetTester tester, AppTab tab) {
    return tester.widget<Icon>(
      find.byKey(ValueKey<String>('nav-slot-icon-${tab.name}')),
    );
  }

  Widget buildDockHost({
    required AppTab selectedTab,
    double? selectionProgress,
    required ValueChanged<AppTab> onSelectTab,
    Size size = const Size(390, 844),
  }) {
    return MediaQuery(
      data: MediaQueryData(
        size: size,
        padding: const EdgeInsets.only(bottom: 34),
      ),
      child: MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFFE8EEF8),
          body: SizedBox.expand(
            child: Stack(
              children: [
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFDDE8F7), Color(0xFFF9F7F2)],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: GlassBottomDock(
                    tabs: AppTab.values,
                    selectedTab: selectedTab,
                    selectionProgress:
                        selectionProgress ?? selectedTab.index.toDouble(),
                    onSelectTab: onSelectTab,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders blur structure and slot icons', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildDockHost(selectedTab: AppTab.home, onSelectTab: (_) {}),
    );

    expect(
      find.byKey(const ValueKey<String>('app-navigation-bar')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('glass-dock-blur')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('glass-dock-active-pill')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('glass-dock-active-pill-gesture')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('nav-home')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('nav-chat')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('nav-slot-icon-home')),
      findsOneWidget,
    );
    expect(slotIcon(tester, AppTab.home).icon, AppTab.home.selectedIcon);
    expect(find.byKey(const ValueKey<String>('nav-label-home')), findsNothing);
    expect(find.byKey(const ValueKey<String>('nav-label-chat')), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('glass-dock-active-content-current')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('glass-dock-active-content-next')),
      findsNothing,
    );
  });

  testWidgets('expands to available width and uses equal slots', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildDockHost(selectedTab: AppTab.home, onSelectTab: (_) {}),
    );

    final barRect = tester.getRect(
      find.byKey(const ValueKey<String>('app-navigation-bar')),
    );
    final scaffoldRect = tester.getRect(find.byType(Scaffold));
    final homeRect = tester.getRect(
      find.byKey(const ValueKey<String>('nav-home')),
    );
    final chatRect = tester.getRect(
      find.byKey(const ValueKey<String>('nav-chat')),
    );
    final diaryRect = tester.getRect(
      find.byKey(const ValueKey<String>('nav-diary')),
    );
    final imageRect = tester.getRect(
      find.byKey(const ValueKey<String>('nav-image')),
    );

    expect(barRect.width, closeTo(scaffoldRect.width - 48, 0.01));
    expect(homeRect.width, closeTo(chatRect.width, 0.01));
    expect(chatRect.width, closeTo(diaryRect.width, 0.01));
    expect(diaryRect.width, closeTo(imageRect.width, 0.01));
  });

  testWidgets('switches selected tab through slot icons only', (
    WidgetTester tester,
  ) async {
    var selectedTab = AppTab.home;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return buildDockHost(
            selectedTab: selectedTab,
            onSelectTab: (tab) {
              setState(() {
                selectedTab = tab;
              });
            },
          );
        },
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('nav-diary')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('glass-dock-active-pill')),
      findsOneWidget,
    );
    expect(slotIcon(tester, AppTab.home).icon, AppTab.home.icon);
    expect(slotIcon(tester, AppTab.diary).icon, AppTab.diary.selectedIcon);
    expect(find.byKey(const ValueKey<String>('nav-label-diary')), findsNothing);
  });

  testWidgets('drags the active pill and settles to nearest tab on release', (
    WidgetTester tester,
  ) async {
    var selectedTab = AppTab.home;
    AppTab? settledTab;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return buildDockHost(
            selectedTab: selectedTab,
            onSelectTab: (tab) {
              settledTab = tab;
              setState(() {
                selectedTab = tab;
              });
            },
          );
        },
      ),
    );

    final pillFinder = find.byKey(
      const ValueKey<String>('glass-dock-active-pill'),
    );
    final handleFinder = find.byKey(
      const ValueKey<String>('glass-dock-active-pill-gesture'),
    );
    final beforeRect = tester.getRect(pillFinder);

    final gesture = await tester.startGesture(tester.getCenter(handleFinder));
    await gesture.moveBy(const Offset(80, 0));
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.moveBy(const Offset(80, 0));
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.moveBy(const Offset(80, 0));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump();

    final dragRect = tester.getRect(pillFinder);
    expect(dragRect.center.dx, greaterThan(beforeRect.center.dx));
    expect(dragRect.top, lessThan(beforeRect.top));
    expect(settledTab, isNull);

    await gesture.up();
    await tester.pumpAndSettle();

    expect(settledTab, AppTab.chat);
    expect(slotIcon(tester, AppTab.chat).icon, AppTab.chat.selectedIcon);
  });

  testWidgets('uses progress to place the pill between neighboring tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildDockHost(
        selectedTab: AppTab.home,
        selectionProgress: 0.5,
        onSelectTab: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    final pillRect = tester.getRect(
      find.byKey(const ValueKey<String>('glass-dock-active-pill')),
    );
    final homeRect = tester.getRect(
      find.byKey(const ValueKey<String>('nav-home')),
    );
    final chatRect = tester.getRect(
      find.byKey(const ValueKey<String>('nav-chat')),
    );
    final slotWidth = tester
        .getRect(find.byKey(const ValueKey<String>('nav-home')))
        .width;

    expect(pillRect.center.dx, greaterThan(homeRect.center.dx));
    expect(pillRect.center.dx, lessThan(chatRect.center.dx));
    expect(pillRect.width, lessThan(slotWidth));
    expect(slotIcon(tester, AppTab.home).icon, AppTab.home.icon);
    expect(slotIcon(tester, AppTab.chat).icon, AppTab.chat.selectedIcon);
    expect(find.byKey(const ValueKey<String>('nav-label-home')), findsNothing);
    expect(find.byKey(const ValueKey<String>('nav-label-chat')), findsNothing);

    final homeOpacity = tester.widget<Opacity>(
      find
          .ancestor(
            of: find.byKey(const ValueKey<String>('nav-slot-icon-home')),
            matching: find.byType(Opacity),
          )
          .first,
    );
    final chatOpacity = tester.widget<Opacity>(
      find
          .ancestor(
            of: find.byKey(const ValueKey<String>('nav-slot-icon-chat')),
            matching: find.byType(Opacity),
          )
          .first,
    );
    expect(homeOpacity.opacity, greaterThan(0.72));
    expect(homeOpacity.opacity, lessThan(1.0));
    expect(chatOpacity.opacity, greaterThan(0.72));
    expect(chatOpacity.opacity, lessThan(1.0));
  });

  testWidgets('semantics selected follows nearest progress index', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildDockHost(
        selectedTab: AppTab.home,
        selectionProgress: 0.6,
        onSelectTab: (_) {},
      ),
    );

    final homeSemantics = tester.widget<Semantics>(
      find.byKey(const ValueKey<String>('nav-semantics-home')),
    );
    final chatSemantics = tester.widget<Semantics>(
      find.byKey(const ValueKey<String>('nav-semantics-chat')),
    );

    expect(homeSemantics.properties.selected, isFalse);
    expect(chatSemantics.properties.selected, isTrue);
  });

  testWidgets('stays stable on a narrow width', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 690);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildDockHost(
        selectedTab: AppTab.image,
        onSelectTab: (_) {},
        size: const Size(320, 690),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey<String>('nav-slot-icon-image')),
      findsOneWidget,
    );
  });

  testWidgets('matches the Home dock golden', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildDockHost(
        selectedTab: AppTab.home,
        selectionProgress: AppTab.home.index.toDouble(),
        onSelectTab: (_) {},
      ),
    );

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/glass_bottom_dock_home.png'),
    );
  });

  testWidgets('matches the Chat dock golden', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildDockHost(
        selectedTab: AppTab.chat,
        selectionProgress: AppTab.chat.index.toDouble(),
        onSelectTab: (_) {},
      ),
    );

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/glass_bottom_dock_chat.png'),
    );
  });

  testWidgets('matches the Diary dock golden', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildDockHost(
        selectedTab: AppTab.diary,
        selectionProgress: AppTab.diary.index.toDouble(),
        onSelectTab: (_) {},
      ),
    );

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/glass_bottom_dock_diary.png'),
    );
  });

  testWidgets('matches the Image dock golden', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildDockHost(
        selectedTab: AppTab.image,
        selectionProgress: AppTab.image.index.toDouble(),
        onSelectTab: (_) {},
      ),
    );

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/glass_bottom_dock_image.png'),
    );
  });
}
