import 'package:flutter/material.dart';
import 'package:gdgoc_2026_prototype/app/shell/app_tab.dart';
import 'package:gdgoc_2026_prototype/app/shell/app_tab_config.dart';
import 'package:gdgoc_2026_prototype/app/shell/widgets/glass_bottom_dock.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialTab = AppTab.home});

  final AppTab initialTab;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _initialTranscript = 'マスター、今日はどんな日だった？\nここに Mori の文字起こしが残るよ。';
  static const _activeTranscript = 'うん、ちゃんと聞こえてるよ。\n今日あったことを、ゆっくり聞かせて。';
  static const _pageAnimationDuration = Duration(milliseconds: 280);

  late final PageController _pageController;
  late AppTab _selectedTab;
  late double _pageProgress;
  late String _homeTranscript;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _pageProgress = widget.initialTab.index.toDouble();
    _homeTranscript = _initialTranscript;
    _pageController = PageController(initialPage: widget.initialTab.index)
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

    final nextProgress = _pageController.page ?? _selectedTab.index.toDouble();
    if ((nextProgress - _pageProgress).abs() < 0.0001) {
      return;
    }

    setState(() {
      _pageProgress = nextProgress;
    });
  }

  Future<void> _animateToTab(AppTab tab) async {
    final targetPage = tab.index;
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
    final tab = AppTab.values[index];
    setState(() {
      _selectedTab = tab;
      _pageProgress = index.toDouble();
    });
  }

  void _startHomeCall() {
    setState(() {
      _homeTranscript = _activeTranscript;
    });
    _animateToTab(AppTab.home);
  }

  @override
  Widget build(BuildContext context) {
    final configs = buildAppTabConfigs(
      context: context,
      onSelectTab: _selectTab,
      onStartHomeCall: _startHomeCall,
      homeTranscriptText: _homeTranscript,
    );
    final mediaQuery = MediaQuery.of(context);
    final adjustedMediaQuery = mediaQuery.copyWith(
      padding: mediaQuery.padding.copyWith(
        bottom:
            mediaQuery.padding.bottom + GlassBottomDock.reservedBottomSpacing,
      ),
      viewPadding: mediaQuery.viewPadding.copyWith(
        bottom:
            mediaQuery.viewPadding.bottom +
            GlassBottomDock.reservedBottomSpacing,
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
          Positioned.fill(
            child: IgnorePointer(
              ignoring: false,
              child: GlassBottomDock(
                tabs: [for (final config in configs) config.tab],
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
