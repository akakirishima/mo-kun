import 'package:flutter/material.dart';
import 'package:gdgoc_2026_prototype/app/shell/app_tab.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/diary_screen.dart';
import 'package:gdgoc_2026_prototype/features/home/presentation/home_screen.dart';
import 'package:gdgoc_2026_prototype/features/settings/presentation/settings_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, this.initialTab = AppTab.home});

  final AppTab initialTab;

  @override
  Widget build(BuildContext context) {
    void openSettings() {
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
    }

    void openDiary() {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DiaryScreen(onSettingsTap: openSettings),
        ),
      );
    }

    if (initialTab == AppTab.diary) {
      return DiaryScreen(onSettingsTap: openSettings);
    }

    return HomeScreen(onSettingsTap: openSettings, onDiaryTap: openDiary);
  }
}
