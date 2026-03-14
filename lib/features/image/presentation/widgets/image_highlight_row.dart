import 'package:flutter/material.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';

class ImageHighlightRow extends StatelessWidget {
  const ImageHighlightRow({super.key, required this.items});

  final List<ImageHighlightItem> items;

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).image;

    return SizedBox(
      height: 112,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final item = items[index];

          return SizedBox(
            key: ValueKey<String>('image-highlight-item-${item.keyName}'),
            width: 78,
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: item.accentColor, width: 1.5),
                  ),
                  child: DecoratedBox(
                    key: ValueKey<String>(
                      'image-highlight-gradient-${item.keyName}',
                    ),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: item.imageGradient,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        item.icon,
                        size: 20,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: palette.highlightText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ImageHighlightItem {
  const ImageHighlightItem({
    required this.keyName,
    required this.title,
    required this.accentColor,
    required this.imageGradient,
    required this.icon,
  });

  final String keyName;
  final String title;
  final Color accentColor;
  final List<Color> imageGradient;
  final IconData icon;
}
