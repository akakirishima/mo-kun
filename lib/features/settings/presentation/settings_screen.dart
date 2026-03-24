import 'package:flutter/material.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';
import 'package:gdgoc_2026_prototype/features/image/presentation/image_screen.dart';
import 'package:gdgoc_2026_prototype/features/settings/presentation/appearance_settings_screen.dart';
import 'package:gdgoc_2026_prototype/features/settings/presentation/character_settings_screen.dart';
import 'package:gdgoc_2026_prototype/features/settings/presentation/home_background_settings_screen.dart';
import 'package:gdgoc_2026_prototype/features/settings/presentation/profile_settings_screen.dart';
import 'package:nes_ui/nes_ui.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsColors = AppearanceScope.paletteOf(context).settings;
    final canPop = Navigator.canPop(context);

    void openAppearanceSettings() {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const AppearanceSettingsScreen(),
        ),
      );
    }

    void openImageSettings() {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ImageScreen(
            onSettingsTap: () => Navigator.of(context).pop(),
          ),
        ),
      );
    }

    void openHomeBackgroundSettings() {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const HomeBackgroundSettingsScreen(),
        ),
      );
    }

    void openProfileSettings() {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const ProfileSettingsScreen(),
        ),
      );
    }

    void openCharacterSettings() {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const CharacterSettingsScreen(),
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
                    if (canPop)
                      NesButton.icon(
                        key: const ValueKey<String>('settings-back-button'),
                        onPressed: () => Navigator.of(context).pop(),
                        type: NesButtonType.normal,
                        icon: NesIcons.leftArrowIndicator,
                        iconSize: const Size.square(18),
                        buttonWidth: 28,
                      )
                    else
                      const SizedBox(width: 48),
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
                    _SettingsSection(
                      title: 'General',
                      items: [
                        _SettingsItemData(
                          tileKey: const ValueKey<String>('settings-item-profile'),
                          icon: NesIcons.user,
                          title: 'プロフィール',
                          subtitle: '表示名やアバターの設定',
                          onTap: openProfileSettings,
                        ),
                        _SettingsItemData(
                          tileKey: const ValueKey<String>(
                            'settings-item-notifications',
                          ),
                          icon: NesIcons.bell,
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
                          icon: NesIcons.gem,
                          title: 'デザイン',
                          subtitle: 'テーマや見た目の調整',
                          onTap: openAppearanceSettings,
                        ),
                        _SettingsItemData(
                          tileKey: const ValueKey<String>(
                            'settings-item-home-background',
                          ),
                          icon: NesIcons.gallery,
                          title: 'HOME背景',
                          subtitle: '昼・夕焼け・夜空 / カスタム画像',
                          onTap: openHomeBackgroundSettings,
                        ),
                        _SettingsItemData(
                          tileKey: const ValueKey<String>('settings-item-image'),
                          icon: NesIcons.gallery,
                          title: 'Image',
                          subtitle: '生成画像と履歴の確認',
                          onTap: openImageSettings,
                        ),
                        _SettingsItemData(
                          tileKey: const ValueKey<String>('settings-item-ai'),
                          icon: NesIcons.robot,
                          title: 'AI / キャラクター',
                          subtitle: '内なる声の反応や雰囲気の調整',
                          onTap: openCharacterSettings,
                        ),
                        _SettingsItemData(
                          tileKey: const ValueKey<String>('settings-item-help'),
                          icon: NesIcons.questionMark,
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
    final settingsColors = AppearanceScope.paletteOf(context).settings;

    return NesContainer(
      label: title,
      backgroundColor: settingsColors.sectionCard,
      borderColor: settingsColors.sectionTitle,
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 8),
      painterBuilder: NesContainerSquareCornerPainter.new,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: settingsColors.shadowColor,
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        child: NesPressable(
          key: data.tileKey,
          onPress: data.onTap ?? () {},
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: settingsColors.tileIconChipFill.withValues(alpha: 0.5),
              border: Border.all(color: settingsColors.tileIconColor, width: 2),
            ),
            child: Row(
              children: [
                NesIcon(
                  iconData: data.icon,
                  size: const Size.square(28),
                  primaryColor: settingsColors.tileIconColor,
                  secondaryColor: Colors.white,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: settingsColors.tileTitle,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: settingsColors.tileSubtitle,
                        ),
                      ),
                    ],
                  ),
                ),
                NesIcon(
                  iconData: NesIcons.rightArrowIndicator,
                  size: const Size.square(18),
                  primaryColor: settingsColors.trailing,
                  secondaryColor: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
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
  final NesIconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
}
