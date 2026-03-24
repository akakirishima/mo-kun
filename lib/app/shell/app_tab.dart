import 'package:flutter/material.dart';

enum AppTab {
  home(
    label: 'ホーム',
    semanticLabel: 'Home tab',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
    accentColor: Color(0xFFF3B4CB),
  ),
  chat(
    label: 'チャット',
    semanticLabel: 'Chat tab',
    icon: Icons.chat_bubble_outline_rounded,
    selectedIcon: Icons.chat_bubble_rounded,
    accentColor: Color(0xFFF3C2A0),
  ),
  diary(
    label: '日記',
    semanticLabel: 'Diary tab',
    icon: Icons.menu_book_outlined,
    selectedIcon: Icons.menu_book_rounded,
    accentColor: Color(0xFFF3D8B3),
  ),
  settings(
    label: '設定',
    semanticLabel: 'Settings tab',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    accentColor: Color(0xFFE8E4DE),
  ),
  image(
    label: 'Image',
    semanticLabel: 'Image tab',
    icon: Icons.image_outlined,
    selectedIcon: Icons.image,
    accentColor: Color(0xFFF1DACF),
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
