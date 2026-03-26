import 'package:flutter/material.dart';
import 'package:gdgoc_2026_prototype/app/shell/app_tab.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/diary_screen.dart';
import 'package:gdgoc_2026_prototype/features/home/presentation/home_screen.dart';
import 'package:gdgoc_2026_prototype/features/settings/presentation/settings_screen.dart';

class AppTabConfig {
  AppTabConfig({required this.tab, required this.screen});

  final AppTab tab;
  final Widget screen;

  Key get screenKey => ValueKey<String>('screen-${tab.name}');

  NavigationDestination get destination {
    return NavigationDestination(
      key: ValueKey<String>('nav-${tab.name}'),
      icon: Semantics(label: tab.semanticLabel, child: Icon(tab.icon)),
      selectedIcon: Semantics(
        label: tab.semanticLabel,
        child: Icon(tab.selectedIcon),
      ),
      label: tab.label,
    );
  }
}

List<AppTabConfig> buildAppTabConfigs({
  required BuildContext context,
  ValueChanged<HomeOverlayMode>? onHomeOverlayModeChanged,
}) {
  void openSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
  }

  return [
    AppTabConfig(
      tab: AppTab.home,
      screen: HomeScreen(
        onSettingsTap: openSettings,
        onDiaryTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const DiaryScreen()),
          );
        },
        onOverlayModeChanged: onHomeOverlayModeChanged,
      ),
    ),
    AppTabConfig(
      tab: AppTab.diary,
      screen: const DiaryScreen(),
    ),
  ];
}
