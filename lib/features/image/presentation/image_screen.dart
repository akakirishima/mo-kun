import 'package:flutter/material.dart';
import 'package:gdgoc_2026_prototype/app/shell/widgets/glass_bottom_dock.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';
import 'package:gdgoc_2026_prototype/features/image/presentation/widgets/image_ai_select_grid.dart';
import 'package:gdgoc_2026_prototype/features/image/presentation/widgets/image_highlight_row.dart';

class ImageScreen extends StatelessWidget {
  const ImageScreen({super.key, required this.onSettingsTap});

  static const _postPlaceholderMessage = '投稿フローはこれから追加します';
  static const _gridBottomPadding = GlassBottomDock.reservedBottomSpacing + 28;

  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppearanceScope.paletteOf(context).image;
    final highlights = [
      ImageHighlightItem(
        keyName: 'meal',
        title: '食事',
        accentColor: palette.highlightAccent,
        imageGradient: palette.highlightGradients[0],
        icon: Icons.restaurant_rounded,
      ),
      ImageHighlightItem(
        keyName: 'workout',
        title: '筋トレ',
        accentColor: palette.highlightAccent,
        imageGradient: palette.highlightGradients[1],
        icon: Icons.fitness_center_rounded,
      ),
      ImageHighlightItem(
        keyName: 'travel',
        title: '旅行',
        accentColor: palette.highlightAccent,
        imageGradient: palette.highlightGradients[2],
        icon: Icons.flight_takeoff_rounded,
      ),
      ImageHighlightItem(
        keyName: 'daily',
        title: '日常',
        accentColor: palette.highlightAccent,
        imageGradient: palette.highlightGradients[3],
        icon: Icons.wb_sunny_outlined,
      ),
    ];
    final aiSelectItems = [
      ImageAiSelectItem(
        keyName: 'sunset',
        title: '夕方ラン',
        tag: '旅行',
        scoreLabel: 'AI Select',
        backgroundGradient: palette.aiTileGradients[0],
        accentColor: palette.aiTileAccent,
        icon: Icons.landscape_rounded,
      ),
      ImageAiSelectItem(
        keyName: 'gym',
        title: '追い込み',
        tag: '筋トレ',
        scoreLabel: 'AI Select',
        backgroundGradient: palette.aiTileGradients[1],
        accentColor: palette.aiTileAccent,
        icon: Icons.sports_gymnastics_rounded,
      ),
      ImageAiSelectItem(
        keyName: 'meal',
        title: '回復メシ',
        tag: '食事',
        scoreLabel: 'AI Select',
        backgroundGradient: palette.aiTileGradients[2],
        accentColor: palette.aiTileAccent,
        icon: Icons.ramen_dining_rounded,
      ),
      ImageAiSelectItem(
        keyName: 'park',
        title: '朝の空気',
        tag: '日常',
        scoreLabel: 'AI Select',
        backgroundGradient: palette.aiTileGradients[3],
        accentColor: palette.aiTileAccent,
        icon: Icons.park_rounded,
      ),
      ImageAiSelectItem(
        keyName: 'trip',
        title: '海辺の休息',
        tag: '旅行',
        scoreLabel: 'AI Select',
        backgroundGradient: palette.aiTileGradients[4],
        accentColor: palette.aiTileAccent,
        icon: Icons.sailing_rounded,
      ),
      ImageAiSelectItem(
        keyName: 'snack',
        title: '補給タイム',
        tag: '食事',
        scoreLabel: 'AI Select',
        backgroundGradient: palette.aiTileGradients[5],
        accentColor: palette.aiTileAccent,
        icon: Icons.local_cafe_rounded,
      ),
    ];

    return Scaffold(
      key: const ValueKey<String>('image-scaffold'),
      backgroundColor: palette.backgroundColor,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        key: const ValueKey<String>('image-post-fab'),
        onPressed: () {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text(_postPlaceholderMessage)),
            );
        },
        heroTag: 'image-post-fab',
        tooltip: '投稿',
        backgroundColor: palette.fabFill,
        foregroundColor: palette.fabForeground,
        elevation: 2,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          key: const PageStorageKey<String>('image-screen-scroll'),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                child: Row(
                  key: const ValueKey<String>('image-screen'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Image',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: palette.titleText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'AI Select',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: palette.subtitleText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: const ValueKey<String>('image-settings-button'),
                      onPressed: onSettingsTap,
                      icon: const Icon(Icons.settings_outlined),
                      tooltip: '設定',
                      color: palette.settingsIcon,
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: ImageHighlightRow(
                key: const ValueKey<String>('image-highlight-row'),
                items: highlights,
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                key: ValueKey<String>('image-ai-select-header'),
                padding: EdgeInsets.fromLTRB(18, 16, 18, 10),
                child: _ImageModeToggle(),
              ),
            ),
            ImageAiSelectGrid(
              key: const ValueKey<String>('image-ai-select-grid'),
              items: aiSelectItems,
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: _gridBottomPadding),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageModeToggle extends StatelessWidget {
  const _ImageModeToggle();

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).image;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Icon(
                    Icons.grid_on_rounded,
                    key: const ValueKey<String>('image-mode-grid'),
                    size: 28,
                    color: palette.modeActive,
                  ),
                  const SizedBox(height: 8),
                  Divider(height: 1, thickness: 2, color: palette.modeActive),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Icon(
                    Icons.auto_awesome_mosaic_outlined,
                    key: const ValueKey<String>('image-mode-ai'),
                    size: 28,
                    color: palette.modeInactive,
                  ),
                  const SizedBox(height: 8),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: palette.modeInactiveDivider,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
