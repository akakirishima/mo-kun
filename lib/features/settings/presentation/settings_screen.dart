import 'package:flutter/material.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';
import 'package:gdgoc_2026_prototype/features/settings/presentation/appearance_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsColors = AppearanceScope.paletteOf(context).settings;

    void openAppearanceSettings() {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const AppearanceSettingsScreen(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        key: const ValueKey<String>('settings-background'),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              settingsColors.backgroundTop,
              settingsColors.backgroundBottom,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            key: const ValueKey<String>('settings-screen'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      key: const ValueKey<String>('settings-back-button'),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      tooltip: '戻る',
                    ),
                    Expanded(
                      child: Text(
                        'Settings',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: settingsColors.headerText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
                  children: [
                    const _SettingsSection(
                      title: 'General',
                      items: [
                        _SettingsItemData(
                          tileKey: ValueKey<String>('settings-item-profile'),
                          icon: Icons.person_outline_rounded,
                          title: 'プロフィール',
                          subtitle: '表示名やアバターの設定',
                        ),
                        _SettingsItemData(
                          tileKey: ValueKey<String>(
                            'settings-item-notifications',
                          ),
                          icon: Icons.notifications_none_rounded,
                          title: '通知',
                          subtitle: 'リマインドやお知らせの受け取り方',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SettingsSection(
                      title: 'Experience',
                      items: [
                        _SettingsItemData(
                          tileKey: const ValueKey<String>(
                            'settings-item-appearance',
                          ),
                          icon: Icons.palette_outlined,
                          title: '表示',
                          subtitle: 'テーマや見た目の調整',
                          onTap: openAppearanceSettings,
                        ),
                        const _SettingsItemData(
                          tileKey: ValueKey<String>('settings-item-ai'),
                          icon: Icons.auto_awesome_outlined,
                          title: 'AI / キャラクター',
                          subtitle: '内なる声の反応や雰囲気の調整',
                        ),
                        const _SettingsItemData(
                          tileKey: ValueKey<String>('settings-item-help'),
                          icon: Icons.help_outline_rounded,
                          title: 'ヘルプ',
                          subtitle: '使い方とサポート情報',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.items});

  final String title;
  final List<_SettingsItemData> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsColors = AppearanceScope.paletteOf(context).settings;

    return Container(
      decoration: BoxDecoration(
        color: settingsColors.sectionCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: settingsColors.shadowColor,
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: settingsColors.sectionTitle,
              ),
            ),
            const SizedBox(height: 6),
            for (final item in items) _SettingsTile(data: item),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.data});

  final _SettingsItemData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsColors = AppearanceScope.paletteOf(context).settings;

    return ListTile(
      key: data.tileKey,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: settingsColors.tileIconChipFill,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(data.icon, color: settingsColors.tileIconColor),
      ),
      title: Text(
        data.title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: settingsColors.tileTitle,
        ),
      ),
      subtitle: Text(
        data.subtitle,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: settingsColors.tileSubtitle,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: settingsColors.trailing,
      ),
      onTap: data.onTap ?? () {},
    );
  }
}

class _SettingsItemData {
  const _SettingsItemData({
    required this.tileKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final Key tileKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
}
