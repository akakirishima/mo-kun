import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/models/diary_book.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/widgets/diary_day_selector.dart';

class DiaryCoverPage extends StatelessWidget {
  const DiaryCoverPage({
    super.key,
    required this.book,
    required this.onSelectorTap,
  });

  final DiaryMonthBook book;
  final VoidCallback onSelectorTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).diary;

    return Container(
      key: const ValueKey<String>('diary-cover-page'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.coverFill, palette.coverAccent],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const baseWidth = 356.0;
          const baseHeight = 640.0;
          final scale = math.min(
            constraints.maxWidth / baseWidth,
            constraints.maxHeight / baseHeight,
          );

          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: baseWidth * scale,
              height: baseHeight * scale,
              child: FittedBox(
                alignment: Alignment.topCenter,
                fit: BoxFit.fill,
                child: SizedBox(
                  width: baseWidth,
                  height: baseHeight,
                  child: Stack(
                    children: [
                      Positioned(
                        right: 30,
                        top: 0,
                        child: Container(
                          width: 24,
                          height: 156,
                          decoration: BoxDecoration(
                            color: palette.paperFill.withValues(alpha: 0.88),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(14),
                              bottomRight: Radius.circular(14),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: palette.spineShadow,
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 18,
                        top: 22,
                        bottom: 26,
                        child: Container(
                          width: 18,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                palette.spineShadow.withValues(alpha: 0.44),
                                palette.spineShadow.withValues(alpha: 0.06),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(46, 40, 28, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                DiaryInlineSelector(
                                  key: const ValueKey<String>(
                                    'diary-cover-selector',
                                  ),
                                  label: book.monthLabel,
                                  onTap: onSelectorTap,
                                  textColor: palette.paperFill,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.24,
                                  ),
                                  borderColor: Colors.white.withValues(
                                    alpha: 0.34,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  textStyle: TextStyle(
                                    color: palette.paperFill,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const Spacer(),
                                const SizedBox(width: 40),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              book.coverTitle,
                              style: TextStyle(
                                color: palette.paperFill,
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                                height: 1.02,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              book.coverSubtitle,
                              style: TextStyle(
                                color: palette.paperFill.withValues(alpha: 0.9),
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 30),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _CoverBadge(
                                  label: '31 Days',
                                  color: palette.paperFill.withValues(
                                    alpha: 0.16,
                                  ),
                                  textColor: palette.paperFill,
                                ),
                                _CoverBadge(
                                  label: 'Swipe to Open',
                                  color: Colors.white.withValues(alpha: 0.28),
                                  textColor: palette.paperFill,
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
            ),
          );
        },
      ),
    );
  }
}

class _CoverBadge extends StatelessWidget {
  const _CoverBadge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
