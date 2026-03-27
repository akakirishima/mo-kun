import 'package:flutter/material.dart';
import 'package:gdgoc_2026_prototype/app/shell/app_tab.dart';
import 'package:gdgoc_2026_prototype/app/shell/widgets/glass_bottom_dock.dart';
import 'package:gdgoc_2026_prototype/features/chat/presentation/chat_screen.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/diary_screen.dart';
import 'package:gdgoc_2026_prototype/features/home/presentation/home_screen.dart';
import 'package:gdgoc_2026_prototype/features/settings/presentation/settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialTab = AppTab.home});

  final AppTab initialTab;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late AppTab _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  void _selectTab(AppTab tab) {
    if (_selectedTab == tab) {
      return;
    }
    setState(() {
      _selectedTab = tab;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = AppTab.navigationTabs;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: GlassBottomDock.reservedBottomSpacing,
              ),
              child: IndexedStack(
                clipBehavior: Clip.none,
                index: tabs.indexOf(_selectedTab),
                children: [
                  HomeScreen(
                    onOverlayModeChanged: (_) {},
                    onSettingsTap: () => _selectTab(AppTab.settings),
                    onDiaryTap: () => _selectTab(AppTab.diary),
                  ),
                  const ChatScreen(),
                  DiaryScreen(onSettingsTap: () => _selectTab(AppTab.settings)),
                  const SettingsScreen(),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: GlassBottomDock(
              tabs: tabs,
              selectedTab: _selectedTab,
              selectionProgress: tabs.indexOf(_selectedTab).toDouble(),
              onSelectTab: _selectTab,
            ),
          ),
        ],
      ),
    );
  }
}
