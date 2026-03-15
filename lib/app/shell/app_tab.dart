import 'package:flutter/material.dart';

enum AppTab {
  home(
    label: 'Room',
    semanticLabel: 'Room tab',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    accentColor: Color(0xFFF3B4CB),
  ),
  chat(
    label: 'Chat',
    semanticLabel: 'Chat tab',
    icon: Icons.chat_bubble_outline,
    selectedIcon: Icons.chat_bubble,
    accentColor: Color(0xFFC8E6FF),
  ),
  diary(
    label: 'Diary',
    semanticLabel: 'Diary tab',
    icon: Icons.menu_book_outlined,
    selectedIcon: Icons.menu_book_rounded,
    accentColor: Color(0xFFF3D8B3),
  ),
  image(
    label: 'Image',
    semanticLabel: 'Image tab',
    icon: Icons.image_outlined,
    selectedIcon: Icons.image,
    accentColor: Color(0xFFE8E4DE),
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

  static const navigationTabs = [AppTab.home, AppTab.diary, AppTab.image];

  static AppTab fromName(String value) {
    final normalized = value.toLowerCase();
    if (normalized == 'voice' || normalized == 'call' || normalized == 'chat') {
      return AppTab.home;
    }

    return AppTab.navigationTabs.firstWhere(
      (tab) => tab.name == normalized,
      orElse: () => AppTab.home,
    );
  }
}
