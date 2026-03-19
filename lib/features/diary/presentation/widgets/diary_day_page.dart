import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdgoc_2026_prototype/core/app/app_providers.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/models/diary_book.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/widgets/diary_day_selector.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/widgets/diary_vertical_text.dart';

const _writingPaperPadding = EdgeInsets.fromLTRB(16, 14, 12, 14);

class DiaryDayPage extends ConsumerWidget {
  static const double writingColumnPitch = 36.0;
  static const double writingRowPitch = 25.0;

  const DiaryDayPage({
    super.key,
    required this.entry,
    required this.monthNumber,
    required this.dateLabel,
    required this.onDateTap,
    required this.bottomClearance,
  });

  final DiaryDayEntry entry;
  final String monthNumber;
  final String dateLabel;
  final VoidCallback onDateTap;
  final double bottomClearance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppearanceScope.paletteOf(context).diary;
    final resolvedImageUrl = ref.watch(
      resolvedImageUrlProvider(entry.imageUrl),
    );

    return Container(
      key: ValueKey<String>('diary-entry-page-${entry.dayNumber}'),
      decoration: BoxDecoration(
        color: palette.paperFill,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: palette.paperEdge, width: 1.5),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const horizontalPadding = 16.0;
          const topPadding = 14.0;
          const bottomPadding = 8.0;
          const selectorHeight = 34.0;
          const selectorGap = 6.0;
          const sectionGap = 8.0;

          final contentBottomGap = bottomClearance.clamp(72.0, 96.0);
          final verticalBudget =
              constraints.maxHeight -
              topPadding -
              bottomPadding -
              contentBottomGap -
              selectorHeight -
              selectorGap -
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
                    height: selectorHeight,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: DiaryInlineSelector(
                        key: ValueKey<String>(
                          'diary-entry-date-selector-${entry.dayNumber}',
                        ),
                        label: dateLabel,
                        onTap: onDateTap,
                        textColor: palette.ink.withValues(alpha: 0.74),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        textStyle: TextStyle(
                          fontFamily: 'NotoSansJP',
                          color: palette.ink.withValues(alpha: 0.72),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          decoration: TextDecoration.none,
                          shadows: const [],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: selectorGap),
                  SizedBox(
                    key: ValueKey<String>(
                      'diary-entry-illustration-${entry.dayNumber}',
                    ),
                    height: illustrationHeight,
                    child: CustomPaint(
                      painter: _ScallopFramePainter(
                        borderColor: palette.paperEdge,
                        shadowColor: palette.pageShadow,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: _DiaryEntryIllustration(
                            entry: entry,
                            resolvedImageUrl: resolvedImageUrl,
                          ),
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
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.42),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: palette.paperEdge),
                      ),
                      child: CustomPaint(
                        painter: _WritingPaperPainter(
                          ruleColor: palette.ruleLine,
                          contentPadding: _writingPaperPadding,
                        ),
                        child: Padding(
                          padding: _writingPaperPadding,
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
      ..color = ruleColor.withValues(alpha: 0.68)
      ..strokeWidth = 1.4;
    const spacing = DiaryDayPage.writingColumnPitch;
    final startX = size.width - contentPadding.right - (spacing / 2);

    for (var x = startX; x >= contentPadding.left; x -= spacing) {
      for (var y = 8.0; y < size.height - 8; y += 11) {
        final segmentEnd = math.min(y + 5, size.height - 8);
        canvas.drawLine(Offset(x, y), Offset(x, segmentEnd), guidePaint);
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
                color: Colors.white.withValues(alpha: 0.22),
                child: Center(
                  child: Image.network(
                    url,
                    key: ValueKey<String>('diary-entry-image-${entry.dayNumber}'),
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
            error: (_, __) => _DiarySketchPlaceholder(
              dayNumber: entry.dayNumber,
              palette: entry.illustrationPalette,
            ),
          ),
        ),
        Positioned(
          left: 14,
          bottom: 14,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                entry.highlightLabel,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontFamily: 'NotoSansJP',
                  color: Colors.black87,
                  fontWeight: FontWeight.w800,
                  decoration: TextDecoration.none,
                  shadows: const [],
                ),
              ),
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
      ..color = Colors.white.withValues(alpha: 0.4)
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

class _ScallopFramePainter extends CustomPainter {
  const _ScallopFramePainter({
    required this.borderColor,
    required this.shadowColor,
  });

  final Color borderColor;
  final Color shadowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final frameRect = Rect.fromLTWH(4, 4, size.width - 8, size.height - 8);
    final path = _scallopPath(frameRect, 16);
    canvas.drawPath(
      path.shift(const Offset(0, 6)),
      Paint()
        ..color = shadowColor.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  Path _scallopPath(Rect rect, double radius) {
    final path = Path();
    final diameter = radius * 2;

    path.moveTo(rect.left + radius, rect.top);
    for (var x = rect.left + radius; x < rect.right - radius; x += diameter) {
      final nextX = math.min(x + diameter, rect.right - radius);
      path.quadraticBezierTo(
        x + radius,
        rect.top - radius * 0.82,
        nextX,
        rect.top,
      );
    }

    for (var y = rect.top + radius; y < rect.bottom - radius; y += diameter) {
      final nextY = math.min(y + diameter, rect.bottom - radius);
      path.quadraticBezierTo(
        rect.right + radius * 0.82,
        y + radius,
        rect.right,
        nextY,
      );
    }

    for (var x = rect.right - radius; x > rect.left + radius; x -= diameter) {
      final nextX = math.max(x - diameter, rect.left + radius);
      path.quadraticBezierTo(
        x - radius,
        rect.bottom + radius * 0.82,
        nextX,
        rect.bottom,
      );
    }

    for (var y = rect.bottom - radius; y > rect.top + radius; y -= diameter) {
      final nextY = math.max(y - diameter, rect.top + radius);
      path.quadraticBezierTo(
        rect.left - radius * 0.82,
        y - radius,
        rect.left,
        nextY,
      );
    }

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _ScallopFramePainter oldDelegate) {
    return oldDelegate.borderColor != borderColor ||
        oldDelegate.shadowColor != shadowColor;
  }
}
