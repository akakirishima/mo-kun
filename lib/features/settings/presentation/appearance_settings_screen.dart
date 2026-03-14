import 'package:flutter/material.dart';
import 'package:gdgoc_2026_prototype/core/theme/app_appearance.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';

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
                    IconButton(
                      key: const ValueKey<String>(
                        'appearance-settings-back-button',
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      tooltip: '戻る',
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
                    Container(
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
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'テーマプリセット',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: settingsColors.sectionTitle,
                                  ),
                            ),
                            const SizedBox(height: 8),
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

    return Container(
      key: const ValueKey<String>('appearance-preview-card'),
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '現在の見た目',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: settingsColors.sectionTitle,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 132,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
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
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.palette_outlined,
                      color: palette.previewAccent,
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

    return InkWell(
      key: ValueKey<String>('appearance-preset-${preset.storageValue}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: tilePalette.previewGradient,
                ),
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: tilePalette.previewAccent,
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
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: tilePalette.previewAccent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
