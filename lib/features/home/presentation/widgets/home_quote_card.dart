import 'package:flutter/material.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';

class HomeQuoteCard extends StatelessWidget {
  const HomeQuoteCard({super.key, required this.transcriptText});

  final String transcriptText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppearanceScope.paletteOf(context).home;

    return Container(
      key: const ValueKey<String>('home-transcript-card'),
      decoration: BoxDecoration(
        color: palette.transcriptFill,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.transcriptOuterBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: palette.transcriptShadow,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(5),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.transcriptInnerBorder, width: 1.5),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [palette.transcriptHighlight, palette.transcriptFill],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _QuoteBadge(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '今日の一言',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: palette.transcriptTitle,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    transcriptText,
                    key: const ValueKey<String>('home-transcript-text'),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: palette.transcriptText,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuoteBadge extends StatelessWidget {
  const _QuoteBadge();

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).home;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: palette.transcriptBadgeFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.transcriptBadgeBorder, width: 1.5),
      ),
      child: Icon(
        Icons.favorite_rounded,
        color: palette.transcriptBadgeIcon,
        size: 22,
      ),
    );
  }
}
