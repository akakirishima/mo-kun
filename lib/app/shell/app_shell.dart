import 'package:flutter/material.dart';
import 'package:gdgoc_2026_prototype/app/shell/app_tab.dart';
import 'package:gdgoc_2026_prototype/app/shell/app_tab_config.dart';
import 'package:gdgoc_2026_prototype/app/shell/widgets/glass_bottom_dock.dart';
import 'package:gdgoc_2026_prototype/features/home/presentation/home_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialTab = AppTab.home});

  final AppTab initialTab;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _pageAnimationDuration = Duration(milliseconds: 280);
  static const _tabs = AppTab.navigationTabs;

  late final PageController _pageController;
  late AppTab _selectedTab;
  late double _pageProgress;
  HomeOverlayMode _homeOverlayMode = HomeOverlayMode.none;

  bool get _shouldShowDock =>
      _selectedTab != AppTab.home || _homeOverlayMode == HomeOverlayMode.none;

  @override
  void initState() {
    super.initState();
    _selectedTab = _tabs.contains(widget.initialTab)
        ? widget.initialTab
        : AppTab.home;
    _pageProgress = _tabs.indexOf(_selectedTab).toDouble();
    _pageController = PageController(initialPage: _tabs.indexOf(_selectedTab))
      ..addListener(_handlePageScroll);
  }

  @override
  void dispose() {
    _pageController
      ..removeListener(_handlePageScroll)
      ..dispose();
    super.dispose();
  }

  void _handlePageScroll() {
    if (!_pageController.hasClients) {
      return;
    }

    final nextProgress =
        _pageController.page ?? _tabs.indexOf(_selectedTab).toDouble();
    if ((nextProgress - _pageProgress).abs() < 0.0001) {
      return;
    }

    setState(() {
      _pageProgress = nextProgress;
    });
  }

  Future<void> _animateToTab(AppTab tab) async {
    final targetPage = _tabs.indexOf(tab);
    final isSettledOnTarget =
        _selectedTab == tab && (_pageProgress - targetPage).abs() < 0.001;
    if (isSettledOnTarget || !_pageController.hasClients) {
      return;
    }

    await _pageController.animateToPage(
      targetPage,
      duration: _pageAnimationDuration,
      curve: Curves.easeOutCubic,
    );
  }

  void _selectTab(AppTab tab) {
    if (_selectedTab != tab) {
      setState(() {
        _selectedTab = tab;
      });
    }
    _animateToTab(tab);
  }

  void _handlePageChanged(int index) {
    final tab = _tabs[index];
    setState(() {
      _selectedTab = tab;
      _pageProgress = index.toDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    final configs = buildAppTabConfigs(
      context: context,
      onHomeOverlayModeChanged: (mode) {
        if (_homeOverlayMode == mode) {
          return;
        }
        setState(() {
          _homeOverlayMode = mode;
        });
      },
    );
    final mediaQuery = MediaQuery.of(context);
    final adjustedMediaQuery = mediaQuery.copyWith(
      padding: mediaQuery.padding.copyWith(
        bottom: _shouldShowDock
            ? mediaQuery.padding.bottom + GlassBottomDock.reservedBottomSpacing
            : mediaQuery.padding.bottom,
      ),
      viewPadding: mediaQuery.viewPadding.copyWith(
        bottom: _shouldShowDock
            ? mediaQuery.viewPadding.bottom +
                  GlassBottomDock.reservedBottomSpacing
            : mediaQuery.viewPadding.bottom,
      ),
    );

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: MediaQuery(
              data: adjustedMediaQuery,
              child: PageView(
                key: const ValueKey<String>('app-page-view'),
                controller: _pageController,
                onPageChanged: _handlePageChanged,
                physics: _selectedTab == AppTab.diary
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),
                children: [
                  for (final config in configs)
                    KeyedSubtree(key: config.screenKey, child: config.screen),
                ],
              ),
            ),
          ),
          if (_shouldShowDock)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: false,
                child: GlassBottomDock(
                  tabs: _tabs,
                  selectedTab: _selectedTab,
                  selectionProgress: _pageProgress,
                  onSelectTab: _selectTab,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
