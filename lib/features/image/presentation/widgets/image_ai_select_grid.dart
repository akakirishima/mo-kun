import 'package:flutter/material.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';

class ImageAiSelectGrid extends StatelessWidget {
  const ImageAiSelectGrid({super.key, required this.items});

  final List<ImageAiSelectItem> items;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.zero,
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = items[index];

          return _AiSelectCard(
            key: ValueKey<String>('image-ai-select-item-${item.keyName}'),
            item: item,
          );
        }, childCount: items.length),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
          childAspectRatio: 1,
        ),
      ),
    );
  }
}

class _AiSelectCard extends StatelessWidget {
  const _AiSelectCard({super.key, required this.item});

  final ImageAiSelectItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppearanceScope.paletteOf(context).image;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          key: ValueKey<String>('image-ai-select-gradient-${item.keyName}'),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: item.backgroundGradient,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 18,
                right: 16,
                child: Icon(
                  item.icon,
                  size: 28,
                  color: palette.aiTileIconTint.withValues(alpha: 0.18),
                ),
              ),
              Positioned(
                left: 14,
                top: 14,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: item.accentColor.withValues(alpha: 0.24),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.transparent,
                palette.aiTileOverlay,
              ],
            ),
          ),
        ),
        Positioned(
          left: 8,
          bottom: 8,
          right: 8,
          child: Text(
            'AI Pick · ${item.tag}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: palette.aiTileText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class ImageAiSelectItem {
  const ImageAiSelectItem({
    required this.keyName,
    required this.title,
    required this.tag,
    required this.scoreLabel,
    required this.backgroundGradient,
    required this.accentColor,
    required this.icon,
  });

  final String keyName;
  final String title;
  final String tag;
  final String scoreLabel;
  final List<Color> backgroundGradient;
  final Color accentColor;
  final IconData icon;
}
