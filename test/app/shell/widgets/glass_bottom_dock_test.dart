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
                    tabs: AppTab.navigationTabs,
                    selectedTab: selectedTab,
                    selectionProgress:
                        selectionProgress ??
                        AppTab.navigationTabs.indexOf(selectedTab).toDouble(),
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
    expect(find.byKey(const ValueKey<String>('nav-home')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('nav-diary')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('nav-image')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('nav-chat')), findsNothing);
    expect(slotIcon(tester, AppTab.home).icon, AppTab.home.selectedIcon);
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
    final diaryRect = tester.getRect(
      find.byKey(const ValueKey<String>('nav-diary')),
    );
    final imageRect = tester.getRect(
      find.byKey(const ValueKey<String>('nav-image')),
    );

    expect(barRect.width, closeTo(scaffoldRect.width - 48, 0.01));
    expect(homeRect.width, closeTo(diaryRect.width, 0.01));
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

    expect(slotIcon(tester, AppTab.home).icon, AppTab.home.icon);
    expect(slotIcon(tester, AppTab.diary).icon, AppTab.diary.selectedIcon);
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
    await gesture.moveBy(const Offset(100, 0));
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.moveBy(const Offset(100, 0));
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.moveBy(const Offset(100, 0));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump();

    final dragRect = tester.getRect(pillFinder);
    expect(dragRect.center.dx, greaterThan(beforeRect.center.dx));
    expect(dragRect.top, lessThan(beforeRect.top));
    expect(settledTab, isNull);

    await gesture.up();
    await tester.pumpAndSettle();

    expect(settledTab, isNot(AppTab.home));
    expect(slotIcon(tester, AppTab.home).icon, AppTab.home.icon);
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
    final diaryRect = tester.getRect(
      find.byKey(const ValueKey<String>('nav-diary')),
    );

    expect(pillRect.center.dx, greaterThan(homeRect.center.dx));
    expect(pillRect.center.dx, lessThan(diaryRect.center.dx));
    expect(slotIcon(tester, AppTab.home).icon, AppTab.home.icon);
    expect(slotIcon(tester, AppTab.diary).icon, AppTab.diary.selectedIcon);
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
    final diarySemantics = tester.widget<Semantics>(
      find.byKey(const ValueKey<String>('nav-semantics-diary')),
    );

    expect(homeSemantics.properties.selected, isFalse);
    expect(diarySemantics.properties.selected, isTrue);
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

  testWidgets('matches the Room dock golden', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildDockHost(
        selectedTab: AppTab.home,
        selectionProgress: 0,
        onSelectTab: (_) {},
      ),
    );

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/glass_bottom_dock_home.png'),
    );
  });

  testWidgets('matches the Diary dock golden', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildDockHost(
        selectedTab: AppTab.diary,
        selectionProgress: 1,
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
        selectionProgress: 2,
        onSelectTab: (_) {},
      ),
    );

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/glass_bottom_dock_image.png'),
    );
  });
}
