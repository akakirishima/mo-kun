import 'package:flutter/material.dart';
import 'package:gdgoc_2026_prototype/core/theme/app_appearance.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';
import 'package:nes_ui/nes_ui.dart';

class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppearanceScope.controllerOf(context);
    final palette = controller.palette;
    final settingsColors = palette.settings;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        key: const ValueKey<String>('appearance-settings-background'),
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
            key: const ValueKey<String>('appearance-settings-screen'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                child: Row(
                  children: [
                    NesButton.icon(
                      key: const ValueKey<String>(
                        'appearance-settings-back-button',
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      type: NesButtonType.normal,
                      icon: NesIcons.leftArrowIndicator,
                      iconSize: const Size.square(18),
                      buttonWidth: 28,
                    ),
                    Expanded(
                      child: Text(
                        '表示',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
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
                    Text(
                      'アプリ全体の雰囲気を切り替えます。',
                      key: const ValueKey<String>('appearance-settings-copy'),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: settingsColors.tileSubtitle,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _AppearancePreviewCard(palette: palette),
                    const SizedBox(height: 18),
                    NesContainer(
                      label: 'テーマプリセット',
                      backgroundColor: settingsColors.sectionCard,
                      borderColor: settingsColors.sectionTitle,
                      padding: const EdgeInsets.fromLTRB(18, 24, 18, 12),
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
                            for (final preset in AppAppearancePreset.values)
                              _AppearancePresetTile(
                                preset: preset,
                                isSelected: controller.preset == preset,
                                onTap: () {
                                  controller.selectPreset(preset);
                                },
                              ),
                          ],
                        ),
                      ),
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

class _AppearancePreviewCard extends StatelessWidget {
  const _AppearancePreviewCard({required this.palette});

  final AppAppearancePalette palette;

  @override
  Widget build(BuildContext context) {
    final settingsColors = palette.settings;

    return NesContainer(
      key: const ValueKey<String>('appearance-preview-card'),
      label: '現在の見た目',
      backgroundColor: settingsColors.sectionCard,
      borderColor: settingsColors.sectionTitle,
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Container(
            height: 132,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: palette.previewGradient,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: palette.previewSurface,
                      border: Border.all(
                        color: settingsColors.sectionTitle,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: NesIcon(
                        iconData: NesIcons.gem,
                        size: const Size.square(24),
                        primaryColor: palette.previewAccent,
                        secondaryColor: Colors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    palette.displayName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: settingsColors.headerText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    palette.shortDescription,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: settingsColors.tileSubtitle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppearancePresetTile extends StatelessWidget {
  const _AppearancePresetTile({
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  final AppAppearancePreset preset;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final currentPalette = AppearanceScope.paletteOf(context);
    final tilePalette = AppAppearancePalette.fromPreset(preset);
    final settingsColors = currentPalette.settings;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: NesPressable(
        key: ValueKey<String>('appearance-preset-${preset.storageValue}'),
        onPress: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: tilePalette.previewSurface.withValues(alpha: 0.45),
            border: Border.all(
              color: isSelected
                  ? tilePalette.previewAccent
                  : settingsColors.tileIconColor,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: tilePalette.previewGradient,
                  ),
                  border: Border.all(color: tilePalette.previewAccent, width: 2),
                ),
                child: Center(
                  child: NesIcon(
                    iconData: NesIcons.gem,
                    size: const Size.square(24),
                    primaryColor: tilePalette.previewAccent,
                    secondaryColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preset.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: settingsColors.tileTitle,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      preset.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: settingsColors.tileSubtitle,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedOpacity(
                key: ValueKey<String>(
                  'appearance-selected-${preset.storageValue}',
                ),
                duration: const Duration(milliseconds: 180),
                opacity: isSelected ? 1 : 0,
                child: NesIcon(
                  iconData: NesIcons.check,
                  size: const Size.square(20),
                  primaryColor: tilePalette.previewAccent,
                  secondaryColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
