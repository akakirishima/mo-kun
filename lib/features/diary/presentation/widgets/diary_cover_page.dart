import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/models/diary_book.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/widgets/diary_retro_components.dart';
import 'package:nes_ui/nes_ui.dart';

const _calendarWeekdayLabels = <String>[
  'SUN',
  'MON',
  'TUE',
  'WED',
  'THU',
  'FRI',
  'SAT',
];

const _coverOuterCornerRadius = 10.0;
const _coverInnerCornerRadius = 8.0;
const _coverBaseWidth = 356.0;
const _coverBaseHeight = 648.0;
const _coverBottomBreathingRoom = 8.0;
const _coverArtboardVerticalShift = 0.0;
const _calendarCardHeight = 286.0;
const _calendarCardTop = (_coverBaseHeight - _calendarCardHeight) / 2;

class DiaryCoverPage extends StatelessWidget {
  const DiaryCoverPage({
    super.key,
    required this.book,
    required this.onSelectorTap,
    required this.onDayTap,
    required this.onPreviousMonthTap,
    required this.onNextMonthTap,
  });

  final DiaryMonthBook book;
  final VoidCallback onSelectorTap;
  final ValueChanged<int> onDayTap;
  final VoidCallback onPreviousMonthTap;
  final VoidCallback onNextMonthTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).diary;
    final monthAccent = diaryMonthAccentColor(book.calendar.monthStart.month);
    final coverFill = Color.lerp(palette.coverFill, monthAccent, 0.34)!;
    final coverAccent = Color.lerp(
      palette.coverAccent,
      Color.lerp(monthAccent, Colors.white, 0.5)!,
      0.26,
    )!;
    final coverTitle = Color.lerp(palette.titleText, monthAccent, 0.12)!;
    final coverFrame = Color.lerp(palette.titleText, monthAccent, 0.18)!;
    final coverPaperEdge = Color.lerp(palette.paperEdge, monthAccent, 0.16)!;
    final coverSpine = Color.lerp(palette.spineShadow, monthAccent, 0.22)!;

    return Container(
      key: const ValueKey<String>('diary-cover-page'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_coverOuterCornerRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [coverFill, coverAccent],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.42),
          width: 2.6,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = math.min(
            constraints.maxWidth / _coverBaseWidth,
            constraints.maxHeight / _coverBaseHeight,
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: _coverBottomBreathingRoom),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Transform.translate(
                offset: const Offset(0, _coverArtboardVerticalShift),
                child: SizedBox(
                  key: const ValueKey<String>('diary-cover-artboard'),
                  width: _coverBaseWidth * scale,
                  height: _coverBaseHeight * scale,
                  child: FittedBox(
                    alignment: Alignment.bottomCenter,
                    fit: BoxFit.fill,
                    child: SizedBox(
                      width: _coverBaseWidth,
                      height: _coverBaseHeight,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                _coverInnerCornerRadius,
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CustomPaint(
                                    painter: _CoverPixelTexturePainter(
                                      lightColor: Colors.white.withValues(
                                        alpha: 0.075,
                                      ),
                                      darkColor: coverFrame.withValues(
                                        alpha: 0.05,
                                      ),
                                    ),
                                  ),
                                  CustomPaint(
                                    painter: _CoverPixelFramePainter(
                                      frameColor: coverFrame.withValues(
                                        alpha: 0.18,
                                      ),
                                      accentColor: Colors.white.withValues(
                                        alpha: 0.22,
                                      ),
                                    ),
                                  ),
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                        _coverOuterCornerRadius,
                                      ),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.white.withValues(alpha: 0.05),
                                          Colors.white.withValues(alpha: 0.015),
                                          Colors.transparent,
                                        ],
                                        stops: const [0.0, 0.18, 0.46],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            right: 30,
                            top: 0,
                            child: Stack(
                              children: [
                                Container(
                                  width: 28,
                                  height: 162,
                                  decoration: BoxDecoration(
                                    color: palette.paperFill.withValues(
                                      alpha: 0.92,
                                    ),
                                    border: Border.all(
                                      color: coverPaperEdge.withValues(
                                        alpha: 0.86,
                                      ),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: coverSpine.withValues(
                                          alpha: 0.18,
                                        ),
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  left: 6,
                                  right: 6,
                                  top: 12,
                                  bottom: 8,
                                  child: CustomPaint(
                                    painter: _BookmarkPixelPainter(
                                      color: coverPaperEdge.withValues(
                                        alpha: 0.36,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            left: 18,
                            top: 22,
                            bottom: 26,
                            child: Container(
                              width: 22,
                              decoration: BoxDecoration(
                                color: coverSpine.withValues(alpha: 0.18),
                                border: Border.all(
                                  color: coverSpine.withValues(alpha: 0.28),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: coverSpine.withValues(alpha: 0.12),
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: CustomPaint(
                                painter: _SpinePixelPainter(
                                  color: coverSpine.withValues(alpha: 0.18),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 46,
                            top: 42,
                            child: NesPressable(
                              key: const ValueKey<String>(
                                'diary-cover-selector',
                              ),
                              onPress: onSelectorTap,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(2, 4, 14, 8),
                                child: Text(
                                  book.monthLabel,
                                  style: TextStyle(
                                    fontFamily: 'NotoSansJP',
                                    color: coverTitle,
                                    fontSize: 44,
                                    fontWeight: FontWeight.w900,
                                    height: 1.0,
                                    decoration: TextDecoration.none,
                                    shadows: const [],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 36,
                            right: 72,
                            child: Row(
                              children: [
                                _MonthArrowButton(
                                  widgetKey: const ValueKey<String>(
                                    'diary-cover-previous-month',
                                  ),
                                  icon: Icons.chevron_left_rounded,
                                  onTap: book.canShowPreviousMonth
                                      ? onPreviousMonthTap
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                _MonthArrowButton(
                                  widgetKey: const ValueKey<String>(
                                    'diary-cover-next-month',
                                  ),
                                  icon: Icons.chevron_right_rounded,
                                  onTap: book.canShowNextMonth
                                      ? onNextMonthTap
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            left: 50,
                            right: 44,
                            top: _calendarCardTop,
                            child: _CalendarCard(
                              calendar: book.calendar,
                              onDayTap: onDayTap,
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({required this.calendar, required this.onDayTap});

  final DiaryMonthCalendar calendar;
  final ValueChanged<int> onDayTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).diary;
    final slots = calendar.daySlots;

    return DiaryRetroPanel(
      key: const ValueKey<String>('diary-cover-calendar'),
      fillColor: palette.paperFill.withValues(alpha: 0.96),
      borderColor: palette.ink.withValues(alpha: 0.52),
      innerBorderColor: palette.ruleLine.withValues(alpha: 0.8),
      shadowColor: palette.titleText.withValues(alpha: 0.12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      textureOpacity: 0.01,
      child: SizedBox(
        height: _calendarCardHeight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: _calendarWeekdayLabels
                  .map(
                    (label) => Expanded(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'NotoSansJP',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: palette.bodyDetail.withValues(alpha: 0.82),
                          letterSpacing: 0.25,
                          decoration: TextDecoration.none,
                          shadows: const [],
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 10),
            Container(
              height: 1.4,
              color: palette.ruleLine.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 10),
            for (var week = 0; week < slots.length; week += 7)
              Padding(
                padding: EdgeInsets.only(
                  bottom: week + 7 < slots.length ? 4 : 0,
                ),
                child: Row(
                  children: [
                    for (var weekdayIndex = 0; weekdayIndex < 7; weekdayIndex++)
                      Expanded(
                        child: _CalendarDayCell(
                          weekdayIndex: weekdayIndex,
                          dayNumber: slots[week + weekdayIndex],
                          isRecorded:
                              slots[week + weekdayIndex] != null &&
                              calendar.isRecordedDay(
                                slots[week + weekdayIndex]!,
                              ),
                          isToday:
                              slots[week + weekdayIndex] != null &&
                              calendar.isToday(slots[week + weekdayIndex]!),
                          onTap:
                              slots[week + weekdayIndex] != null &&
                                  calendar.isRecordedDay(
                                    slots[week + weekdayIndex]!,
                                  )
                              ? () => onDayTap(slots[week + weekdayIndex]!)
                              : null,
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

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.weekdayIndex,
    required this.dayNumber,
    required this.isRecorded,
    required this.isToday,
    required this.onTap,
  });

  final int weekdayIndex;
  final int? dayNumber;
  final bool isRecorded;
  final bool isToday;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).diary;

    if (dayNumber == null) {
      return const SizedBox(height: 34);
    }

    final textColor = switch (weekdayIndex) {
      0 => const Color(0xFF9B3E6A),
      6 => const Color(0xFF4543B9),
      _ => palette.ink.withValues(alpha: 0.86),
    };

    return SizedBox(
      height: 34,
      child: NesPressable(
        key: ValueKey<String>('diary-cover-day-button-$dayNumber'),
        disabled: onTap == null,
        onPress: onTap,
        child: Center(
          child: SizedBox(
            key: ValueKey<String>('diary-cover-day-$dayNumber'),
            width: 32,
            height: 34,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isToday)
                        Container(
                          key: ValueKey<String>(
                            'diary-cover-day-today-$dayNumber',
                          ),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFEDAE78),
                              width: 4,
                            ),
                          ),
                        ),
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontFamily: 'NotoSansJP',
                          fontSize: 16,
                          fontWeight: isRecorded
                              ? FontWeight.w800
                              : FontWeight.w700,
                          color: textColor,
                          decoration: TextDecoration.none,
                          shadows: const [],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 6,
                  child: isRecorded
                      ? Container(
                          key: ValueKey<String>(
                            'diary-cover-day-recorded-$dayNumber',
                          ),
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: palette.ink.withValues(alpha: 0.84),
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthArrowButton extends StatelessWidget {
  const _MonthArrowButton({
    required this.widgetKey,
    required this.icon,
    required this.onTap,
  });

  final Key widgetKey;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).diary;

    return Opacity(
      opacity: onTap == null ? 0.45 : 1,
      child: DiaryRetroPressable(
        key: widgetKey,
        fillColor: Colors.white.withValues(alpha: 0.16),
        borderColor: Colors.white.withValues(alpha: 0.42),
        onPress: onTap,
        disabled: onTap == null,
        width: 38,
        height: 38,
        padding: EdgeInsets.zero,
        shadowColor: palette.titleText.withValues(alpha: 0.12),
        child: Icon(icon, size: 18, color: palette.paperFill),
      ),
    );
  }
}

class _CoverPixelTexturePainter extends CustomPainter {
  const _CoverPixelTexturePainter({
    required this.lightColor,
    required this.darkColor,
  });

  final Color lightColor;
  final Color darkColor;

  @override
  void paint(Canvas canvas, Size size) {
    const cellSize = 12.0;
    const primaryPixel = 4.0;
    const accentPixel = 2.0;
    final lightPaint = Paint()..color = lightColor;
    final darkPaint = Paint()..color = darkColor;

    for (var row = 0; row * cellSize < size.height; row++) {
      for (var column = 0; column * cellSize < size.width; column++) {
        final left = column * cellSize;
        final top = row * cellSize;
        final primaryPaint = (row + column).isEven ? lightPaint : darkPaint;
        final secondaryPaint = (row + column).isEven ? darkPaint : lightPaint;
        canvas.drawRect(
          Rect.fromLTWH(left + 1, top + 1, primaryPixel, primaryPixel),
          primaryPaint,
        );
        canvas.drawRect(
          Rect.fromLTWH(left + 6, top + 6, primaryPixel, primaryPixel),
          secondaryPaint,
        );
        canvas.drawRect(
          Rect.fromLTWH(left + 4, top + 2, accentPixel, accentPixel),
          secondaryPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CoverPixelTexturePainter oldDelegate) {
    return oldDelegate.lightColor != lightColor ||
        oldDelegate.darkColor != darkColor;
  }
}

class _CoverPixelFramePainter extends CustomPainter {
  const _CoverPixelFramePainter({
    required this.frameColor,
    required this.accentColor,
  });

  final Color frameColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final framePaint = Paint()..color = frameColor;
    final accentPaint = Paint()..color = accentColor;
    const thickness = 3.0;
    const length = 28.0;
    const inset = 14.0;

    void corner(double left, double top, bool right, bool bottom) {
      final x = right ? size.width - inset - length : inset;
      final y = bottom ? size.height - inset - length : inset;
      canvas.drawRect(
        Rect.fromLTWH(x, right ? y : y, length, thickness),
        framePaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          right ? size.width - inset - thickness : inset,
          y,
          thickness,
          length,
        ),
        framePaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          right ? size.width - inset - thickness - 6 : inset + thickness,
          bottom ? size.height - inset - thickness - 6 : inset + thickness,
          6,
          6,
        ),
        accentPaint,
      );
    }

    corner(inset, inset, false, false);
    corner(inset, inset, true, false);
    corner(inset, inset, false, true);
    corner(inset, inset, true, true);
  }

  @override
  bool shouldRepaint(covariant _CoverPixelFramePainter oldDelegate) {
    return oldDelegate.frameColor != frameColor ||
        oldDelegate.accentColor != accentColor;
  }
}

class _SpinePixelPainter extends CustomPainter {
  const _SpinePixelPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const blockHeight = 10.0;
    const gap = 6.0;

    for (var y = 8.0; y < size.height - 8; y += blockHeight + gap) {
      canvas.drawRect(Rect.fromLTWH(4, y, size.width - 8, blockHeight), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpinePixelPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _BookmarkPixelPainter extends CustomPainter {
  const _BookmarkPixelPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const pixel = 4.0;

    for (var y = 0.0; y < size.height; y += 12) {
      canvas.drawRect(Rect.fromLTWH(0, y, pixel, pixel), paint);
      canvas.drawRect(
        Rect.fromLTWH(size.width - pixel, y + 4, pixel, pixel),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BookmarkPixelPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
