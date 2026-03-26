import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdgoc_2026_prototype/core/app/app_providers.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/models/diary_book.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/widgets/diary_retro_components.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/widgets/diary_vertical_text.dart';

const _writingPaperPadding = EdgeInsets.fromLTRB(16, 14, 12, 14);

class DiaryDayPage extends ConsumerWidget {
  static const double writingColumnPitch = 36.0;
  static const double writingRowPitch = 25.0;

  const DiaryDayPage({
    super.key,
    required this.entry,
    required this.monthNumber,
    required this.bottomClearance,
  });

  final DiaryDayEntry entry;
  final String monthNumber;
  final double bottomClearance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppearanceScope.paletteOf(context).diary;
    final resolvedImageUrl = ref.watch(
      resolvedImageUrlProvider(entry.imageUrl),
    );

    return DiaryRetroPanel(
      key: ValueKey<String>('diary-entry-page-${entry.dayNumber}'),
      fillColor: palette.paperFill,
      borderColor: palette.paperEdge.withValues(alpha: 0.96),
      innerBorderColor: palette.ruleLine.withValues(alpha: 0.78),
      shadowColor: palette.pageShadow.withValues(alpha: 0.16),
      padding: EdgeInsets.zero,
      textureOpacity: 0.02,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const horizontalPadding = 16.0;
          const topPadding = 14.0;
          const bottomPadding = 8.0;
          const sectionGap = 8.0;

          final contentBottomGap = bottomClearance.clamp(16.0, 32.0);
          final verticalBudget =
              constraints.maxHeight -
              topPadding -
              bottomPadding -
              contentBottomGap -
              sectionGap;
          final illustrationHeight = (verticalBudget * 0.42).clamp(
            186.0,
            228.0,
          );
          final writingHeight = math.max(
            180.0,
            verticalBudget - illustrationHeight,
          );

          return Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                horizontalPadding,
                topPadding,
                horizontalPadding,
                bottomPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    key: ValueKey<String>(
                      'diary-entry-illustration-${entry.dayNumber}',
                    ),
                    height: illustrationHeight,
                    child: DiaryRetroPanel(
                      fillColor: palette.cardFill,
                      borderColor: palette.paperEdge.withValues(alpha: 0.96),
                      innerBorderColor: palette.ruleLine.withValues(
                        alpha: 0.88,
                      ),
                      shadowColor: palette.pageShadow.withValues(alpha: 0.14),
                      accentColor: entry.illustrationPalette[2],
                      radius: 20,
                      innerRadius: 15,
                      padding: const EdgeInsets.all(10),
                      textureOpacity: 0.04,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _DiaryEntryIllustration(
                          entry: entry,
                          resolvedImageUrl: resolvedImageUrl,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: sectionGap),
                  SizedBox(
                    key: ValueKey<String>(
                      'diary-entry-writing-paper-${entry.dayNumber}',
                    ),
                    height: writingHeight,
                    child: DiaryRetroPanel(
                      fillColor: palette.cardFill.withValues(alpha: 0.95),
                      borderColor: palette.paperEdge.withValues(alpha: 0.98),
                      innerBorderColor: palette.ruleLine.withValues(
                        alpha: 0.88,
                      ),
                      shadowColor: palette.pageShadow.withValues(alpha: 0.1),
                      accentColor: palette.coverAccent,
                      radius: 20,
                      innerRadius: 16,
                      padding: _writingPaperPadding,
                      textureOpacity: 0.035,
                      child: CustomPaint(
                        painter: _WritingPaperPainter(
                          ruleColor: palette.ruleLine,
                          contentPadding: _writingPaperPadding,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: DiaryVerticalText(
                                key: ValueKey<String>(
                                  'diary-body-${entry.dayNumber}',
                                ),
                                text: entry.body,
                                color: palette.ink,
                                fontSize: 24,
                                columnPitch: writingColumnPitch,
                                rowPitch: writingRowPitch,
                              ),
                            ),
                            SizedBox(
                              key: ValueKey<String>(
                                'diary-entry-meta-column-${entry.dayNumber}',
                              ),
                              width: writingColumnPitch,
                              child: DiaryVerticalText(
                                key: ValueKey<String>(
                                  'diary-entry-meta-text-${entry.dayNumber}',
                                ),
                                text: _entryDateMetaText(
                                  entry,
                                  monthNumber: monthNumber,
                                ),
                                color: palette.ink.withValues(alpha: 0.88),
                                fontSize: 26,
                                columnPitch: writingColumnPitch,
                                rowPitch: writingRowPitch,
                                columnKeyPrefix:
                                    'diary-entry-meta-glyph-column-${entry.dayNumber}',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

String _entryDateMetaText(DiaryDayEntry entry, {required String monthNumber}) {
  return '$monthNumber月${entry.dayNumber}日${entry.weekdayLabel}曜日';
}

class _WritingPaperPainter extends CustomPainter {
  const _WritingPaperPainter({
    required this.ruleColor,
    required this.contentPadding,
  });

  final Color ruleColor;
  final EdgeInsets contentPadding;

  @override
  void paint(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = ruleColor.withValues(alpha: 0.62)
      ..strokeWidth = 1.4;
    final accentPaint = Paint()
      ..color = ruleColor.withValues(alpha: 0.38)
      ..strokeWidth = 1.0;
    const spacing = DiaryDayPage.writingColumnPitch;
    final startX = size.width - contentPadding.right - (spacing / 2);

    for (var x = startX; x >= contentPadding.left; x -= spacing) {
      canvas.drawLine(
        Offset(x, contentPadding.top * 0.45),
        Offset(x, size.height - (contentPadding.bottom * 0.45)),
        guidePaint,
      );
      for (
        var y = contentPadding.top + 12;
        y < size.height - contentPadding.bottom;
        y += 32
      ) {
        canvas.drawLine(Offset(x - 6, y), Offset(x + 6, y), accentPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WritingPaperPainter oldDelegate) {
    return oldDelegate.ruleColor != ruleColor ||
        oldDelegate.contentPadding != contentPadding;
  }
}

class _DiaryEntryIllustration extends StatelessWidget {
  const _DiaryEntryIllustration({
    required this.entry,
    required this.resolvedImageUrl,
  });

  final DiaryDayEntry entry;
  final AsyncValue<String?> resolvedImageUrl;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                entry.illustrationPalette[0],
                entry.illustrationPalette[1].withValues(alpha: 0.78),
              ],
            ),
          ),
          child: resolvedImageUrl.when(
            data: (url) {
              if (url == null || url.isEmpty) {
                return _DiarySketchPlaceholder(
                  dayNumber: entry.dayNumber,
                  palette: entry.illustrationPalette,
                );
              }
              return ColoredBox(
                color: Colors.white.withValues(alpha: 0.18),
                child: Center(
                  child: Image.network(
                    url,
                    key: ValueKey<String>(
                      'diary-entry-image-${entry.dayNumber}',
                    ),
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    errorBuilder: (context, error, stackTrace) {
                      return _DiarySketchPlaceholder(
                        dayNumber: entry.dayNumber,
                        palette: entry.illustrationPalette,
                      );
                    },
                  ),
                ),
              );
            },
            loading: () => Center(
              child: CircularProgressIndicator(
                key: ValueKey<String>(
                  'diary-entry-image-loading-${entry.dayNumber}',
                ),
                strokeWidth: 2,
              ),
            ),
            error: (_, _) => _DiarySketchPlaceholder(
              dayNumber: entry.dayNumber,
              palette: entry.illustrationPalette,
            ),
          ),
        ),
      ],
    );
  }
}

class _DiarySketchPlaceholder extends StatelessWidget {
  const _DiarySketchPlaceholder({
    required this.dayNumber,
    required this.palette,
  });

  final int dayNumber;
  final List<Color> palette;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      key: ValueKey<String>('diary-entry-image-placeholder-$dayNumber'),
      painter: _DiarySketchPainter(palette: palette),
      child: const SizedBox.expand(),
    );
  }
}

class _DiarySketchPainter extends CustomPainter {
  const _DiarySketchPainter({required this.palette});

  final List<Color> palette;

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(
      sky,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette[0], palette[1].withValues(alpha: 0.78)],
        ).createShader(sky),
    );

    final sunPaint = Paint()..color = palette[2].withValues(alpha: 0.88);
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.22),
      20,
      sunPaint,
    );

    final hillOne = Path()
      ..moveTo(0, size.height * 0.75)
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.48,
        size.width * 0.5,
        size.height * 0.72,
      )
      ..quadraticBezierTo(
        size.width * 0.76,
        size.height * 0.9,
        size.width,
        size.height * 0.62,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      hillOne,
      Paint()..color = palette[1].withValues(alpha: 0.85),
    );

    final hillTwo = Path()
      ..moveTo(0, size.height * 0.88)
      ..quadraticBezierTo(
        size.width * 0.26,
        size.height * 0.66,
        size.width * 0.55,
        size.height * 0.84,
      )
      ..quadraticBezierTo(
        size.width * 0.8,
        size.height,
        size.width,
        size.height * 0.8,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      hillTwo,
      Paint()..color = palette[0].withValues(alpha: 0.72),
    );

    final framePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.36)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.11, size.height * 0.18, 72, 62),
        const Radius.circular(16),
      ),
      framePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.58, size.height * 0.38, 88, 64),
        const Radius.circular(18),
      ),
      framePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DiarySketchPainter oldDelegate) {
    return oldDelegate.palette != palette;
  }
}
