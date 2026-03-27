import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdgoc_2026_prototype/core/app/app_providers.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/models/diary_book.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/widgets/diary_retro_components.dart';

const _writingPaperPadding = EdgeInsets.fromLTRB(16, 14, 12, 14);
const _debugShowWritingGrid = false;
const _writingGuideTickInset = 22.0;
const _writingGuideTickHalfHeight = 5.0;

class DiaryDayPage extends ConsumerWidget {
  static const double writingLineHeight = 1.85;
  static const double writingGuideTickSpacing = 32.0;
  static const double headerFontSize = 19.0;
  static const double bodyFontSize = 18.0;
  static const double bodyScrollRightPadding = 4.0;
  static const double bodyScrollBottomPadding = 8.0;

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
    final bodyTextStyle = TextStyle(
      color: palette.ink,
      fontSize: bodyFontSize,
      height: writingLineHeight,
    );
    final bodyStrutStyle = StrutStyle(
      fontSize: bodyFontSize,
      height: writingLineHeight,
      forceStrutHeight: true,
    );
    final linePitch = _resolvedLinePitch(
      bodyTextStyle,
      strutStyle: bodyStrutStyle,
    );
    final headerLinePitch = linePitch;
    final headerTextStyle = TextStyle(
      color: palette.ink.withValues(alpha: 0.9),
      fontSize: headerFontSize,
      fontWeight: FontWeight.w700,
      height: linePitch / headerFontSize,
    );
    final headerStrutStyle = StrutStyle(
      fontSize: headerFontSize,
      height: linePitch / headerFontSize,
      fontWeight: FontWeight.w700,
      forceStrutHeight: true,
    );
    final headerText = _entryDateHeaderText(entry, monthNumber: monthNumber);

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
                          linePitch: linePitch,
                          headerLinePitch: headerLinePitch,
                          showDebugGrid: _debugShowWritingGrid,
                          headerText: headerText,
                          headerTextStyle: headerTextStyle,
                          headerStrutStyle: headerStrutStyle,
                          bodyText: entry.body,
                          bodyTextStyle: bodyTextStyle,
                          bodyStrutStyle: bodyStrutStyle,
                          bodyRightPadding: bodyScrollRightPadding,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              height: headerLinePitch,
                              child: Text(
                                headerText,
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                                softWrap: false,
                                strutStyle: headerStrutStyle,
                                style: headerTextStyle,
                              ),
                            ),
                            const SizedBox(height: 0),
                            Expanded(
                              child: ScrollConfiguration(
                                behavior: const _NoGlowScrollBehavior(),
                                child: SingleChildScrollView(
                                  key: ValueKey<String>(
                                    'diary-body-${entry.dayNumber}',
                                  ),
                                  padding: const EdgeInsets.only(
                                    right: bodyScrollRightPadding,
                                    bottom: bodyScrollBottomPadding,
                                  ),
                                  child: Text(
                                    entry.body,
                                    style: bodyTextStyle,
                                    strutStyle: bodyStrutStyle,
                                  ),
                                ),
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

String _entryDateHeaderText(DiaryDayEntry entry, {required String monthNumber}) {
  return '$monthNumber月${entry.dayNumber}日 ${_weekdayKanji(entry.weekdayLabel)}曜日';
}

String _weekdayKanji(String weekdayLabel) {
  switch (weekdayLabel) {
    case 'げつ':
      return '月';
    case 'か':
      return '火';
    case 'すい':
      return '水';
    case 'もく':
      return '木';
    case 'きん':
      return '金';
    case 'ど':
      return '土';
    default:
      return '日';
  }
}

class _WritingPaperPainter extends CustomPainter {
  const _WritingPaperPainter({
    required this.ruleColor,
    required this.linePitch,
    required this.headerLinePitch,
    required this.showDebugGrid,
    required this.headerText,
    required this.headerTextStyle,
    required this.headerStrutStyle,
    required this.bodyText,
    required this.bodyTextStyle,
    required this.bodyStrutStyle,
    required this.bodyRightPadding,
  });

  final Color ruleColor;
  final double linePitch;
  final double headerLinePitch;
  final bool showDebugGrid;
  final String headerText;
  final TextStyle headerTextStyle;
  final StrutStyle headerStrutStyle;
  final String bodyText;
  final TextStyle bodyTextStyle;
  final StrutStyle bodyStrutStyle;
  final double bodyRightPadding;

  @override
  void paint(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = ruleColor.withValues(alpha: 0.62)
      ..strokeWidth = 1.4;
    final accentPaint = Paint()
      ..color = ruleColor.withValues(alpha: 0.28)
      ..strokeWidth = 1.0;
    final debugPaint = Paint()
      ..color = ruleColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final headerWidth = size.width;
    final bodyWidth = math.max(0.0, size.width - bodyRightPadding);
    final headerPainter = _buildTextPainter(
      text: headerText,
      style: headerTextStyle,
      strutStyle: headerStrutStyle,
      maxWidth: headerWidth,
      maxLines: 1,
    );
    final bodyPainter = _buildTextPainter(
      text: bodyText,
      style: bodyTextStyle,
      strutStyle: bodyStrutStyle,
      maxWidth: bodyWidth,
    );
    final headerMetrics = headerPainter.computeLineMetrics();
    final bodyMetrics = bodyPainter.computeLineMetrics();
    final headerOriginY = 0.0;
    final bodyOriginY = headerLinePitch;

    if (showDebugGrid) {
      canvas.drawRect(Offset.zero & size, debugPaint);
    }

    if (headerMetrics.isNotEmpty) {
      _drawGuideLine(
        canvas,
        y: headerOriginY + _ruleYForMetrics(headerMetrics.first),
        size: size,
        guidePaint: guidePaint,
        accentPaint: accentPaint,
      );
    }

    for (final metrics in bodyMetrics) {
      final y = bodyOriginY + _ruleYForMetrics(metrics);
      if (y > size.height) {
        break;
      }
      _drawGuideLine(
        canvas,
        y: y,
        size: size,
        guidePaint: guidePaint,
        accentPaint: accentPaint,
      );
    }

    var fillY = bodyMetrics.isEmpty
        ? bodyOriginY + linePitch
        : bodyOriginY + _ruleYForMetrics(bodyMetrics.last) + linePitch;

    while (fillY <= size.height) {
      _drawGuideLine(
        canvas,
        y: fillY,
        size: size,
        guidePaint: guidePaint,
        accentPaint: accentPaint,
      );
      fillY += linePitch;
    }
  }

  void _drawGuideLine(
    Canvas canvas, {
    required double y,
    required Size size,
    required Paint guidePaint,
    required Paint accentPaint,
  }) {
    canvas.drawLine(
      Offset.zero.translate(0, y),
      Offset(size.width, y),
      guidePaint,
    );
    for (
      var x = _writingGuideTickInset;
      x < size.width;
      x += DiaryDayPage.writingGuideTickSpacing
    ) {
      canvas.drawLine(
        Offset(x, y - _writingGuideTickHalfHeight),
        Offset(x, y + _writingGuideTickHalfHeight),
        accentPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WritingPaperPainter oldDelegate) {
    return oldDelegate.ruleColor != ruleColor ||
        oldDelegate.linePitch != linePitch ||
        oldDelegate.headerLinePitch != headerLinePitch ||
        oldDelegate.showDebugGrid != showDebugGrid ||
        oldDelegate.headerText != headerText ||
        oldDelegate.headerTextStyle != headerTextStyle ||
        oldDelegate.headerStrutStyle != headerStrutStyle ||
        oldDelegate.bodyText != bodyText ||
        oldDelegate.bodyTextStyle != bodyTextStyle ||
        oldDelegate.bodyStrutStyle != bodyStrutStyle ||
        oldDelegate.bodyRightPadding != bodyRightPadding;
  }
}

double _resolvedLinePitch(TextStyle style, {StrutStyle? strutStyle}) {
  final painter = _buildTextPainter(
    text: 'あ',
    style: style,
    strutStyle: strutStyle,
    maxWidth: double.infinity,
  );
  final metrics = painter.computeLineMetrics();
  return metrics.isNotEmpty ? metrics.first.height : painter.preferredLineHeight;
}

double _ruleYForMetrics(LineMetrics metrics) => metrics.baseline;

TextPainter _buildTextPainter({
  required String text,
  required TextStyle style,
  StrutStyle? strutStyle,
  required double maxWidth,
  int? maxLines,
}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    strutStyle: strutStyle,
    maxLines: maxLines,
    ellipsis: maxLines == null ? null : '',
  );
  painter.layout(maxWidth: maxWidth);
  return painter;
}

class _NoGlowScrollBehavior extends ScrollBehavior {
  const _NoGlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
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
