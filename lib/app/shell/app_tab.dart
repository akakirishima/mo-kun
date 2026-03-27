import 'package:flutter/material.dart';

const _bottomDockSelectedColor = Color(0xFFF0C48A);

enum AppTab {
  home(
    label: 'ホーム',
    semanticLabel: 'Home tab',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
    accentColor: _bottomDockSelectedColor,
  ),
  chat(
    label: 'チャット',
    semanticLabel: 'Chat tab',
    icon: Icons.chat_bubble_outline_rounded,
    selectedIcon: Icons.chat_bubble_rounded,
    accentColor: _bottomDockSelectedColor,
  ),
  diary(
    label: '日記',
    semanticLabel: 'Diary tab',
    icon: Icons.menu_book_outlined,
    selectedIcon: Icons.menu_book_rounded,
    accentColor: _bottomDockSelectedColor,
  ),
  settings(
    label: '設定',
    semanticLabel: 'Settings tab',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    accentColor: _bottomDockSelectedColor,
  ),
  image(
    label: 'Image',
    semanticLabel: 'Image tab',
    icon: Icons.image_outlined,
    selectedIcon: Icons.image,
    accentColor: _bottomDockSelectedColor,
  );

  const AppTab({
    required this.label,
    required this.semanticLabel,
    required this.icon,
    required this.selectedIcon,
    required this.accentColor,
  });

  final String label;
  final String semanticLabel;
  final IconData icon;
  final IconData selectedIcon;
  final Color accentColor;

  static const navigationTabs = [
    AppTab.home,
    AppTab.chat,
    AppTab.diary,
    AppTab.settings,
  ];

  static AppTab fromName(String value) {
    final normalized = value.toLowerCase();
    if (normalized == 'voice' || normalized == 'call') {
      return AppTab.home;
    }
    if (normalized == 'photo' || normalized == 'gallery') {
      return AppTab.settings;
    }

    return AppTab.values.firstWhere(
      (tab) => tab.name == normalized,
      orElse: () => AppTab.home,
    );
  }
}
