import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/models/diary_book.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/widgets/diary_cover_page.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/widgets/diary_day_page.dart';

const _pageFrameCornerRadius = 10.0;
const _pageBackdropCornerRadius = 8.0;
const _pageSpineCornerRadius = 4.0;

class DiaryBookViewport extends StatelessWidget {
  const DiaryBookViewport({
    super.key,
    required this.book,
    required this.controller,
    required this.onPageChanged,
    required this.onOpenSelector,
    required this.onOpenEntryForDay,
    required this.onShowPreviousMonth,
    required this.onShowNextMonth,
    required this.dayPageBottomClearance,
  });

  final DiaryMonthBook book;
  final PageController controller;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onOpenSelector;
  final ValueChanged<int> onOpenEntryForDay;
  final VoidCallback onShowPreviousMonth;
  final VoidCallback onShowNextMonth;
  final double dayPageBottomClearance;

  String get _monthNumber {
    final match = RegExp(r'(\d+)月').firstMatch(book.monthLabel);
    return match?.group(1) ?? '3';
  }

  String _entryDateLabel(DiaryDayEntry entry) {
    return '$_monthNumber月${entry.dayNumber}日';
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).diary;
    final monthAccent = diaryMonthAccentColor(book.calendar.monthStart.month);
    final spineTint = Color.lerp(palette.paperEdge, monthAccent, 0.22)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(constraints.maxWidth, 640.0);

        return Center(
          child: SizedBox(
            key: const ValueKey<String>('diary-book-viewport'),
            width: width,
            height: constraints.maxHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(1, 0, 1, 0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: _PageStackBackdrop(monthAccent: monthAccent),
                  ),
                  Positioned(
                    top: 8,
                    bottom: 8,
                    left: 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          _pageSpineCornerRadius,
                        ),
                        color: spineTint.withValues(alpha: 0.22),
                        border: Border.all(
                          color: spineTint.withValues(alpha: 0.36),
                          width: 1.4,
                        ),
                      ),
                      child: const SizedBox(width: 12),
                    ),
                  ),
                  PageView.builder(
                    key: const ValueKey<String>('diary-book-page-view'),
                    controller: controller,
                    clipBehavior: Clip.none,
                    onPageChanged: onPageChanged,
                    itemCount: book.pageCount,
                    itemBuilder: (context, index) {
                      final entry = book.entryAt(index);
                      final pageChild = entry == null
                          ? DiaryCoverPage(
                              book: book,
                              onSelectorTap: onOpenSelector,
                              onDayTap: onOpenEntryForDay,
                              onPreviousMonthTap: onShowPreviousMonth,
                              onNextMonthTap: onShowNextMonth,
                            )
                          : DiaryDayPage(
                              entry: entry,
                              monthNumber: _monthNumber,
                              dateLabel: _entryDateLabel(entry),
                              onDateTap: onOpenSelector,
                              bottomClearance: dayPageBottomClearance,
                            );

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                        child: _AnimatedDiaryPageFrame(
                          controller: controller,
                          index: index,
                          child: pageChild,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PageStackBackdrop extends StatelessWidget {
  const _PageStackBackdrop({required this.monthAccent});

  final Color monthAccent;

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).diary;
    final frontFill = Color.lerp(palette.paperFill, monthAccent, 0.14)!;
    final backFill = Color.lerp(palette.paperFill, monthAccent, 0.09)!;
    final backdropEdge = Color.lerp(palette.paperEdge, monthAccent, 0.18)!;

    return Stack(
      children: [
        Positioned(
          left: 8,
          right: 4,
          top: 8,
          bottom: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: frontFill.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(_pageBackdropCornerRadius),
              border: Border.all(
                color: backdropEdge.withValues(alpha: 0.32),
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: palette.pageShadow.withValues(alpha: 0.08),
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 12,
          right: 1,
          top: 14,
          bottom: -2,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: backFill.withValues(alpha: 0.38),
              borderRadius: BorderRadius.circular(_pageBackdropCornerRadius),
              border: Border.all(
                color: backdropEdge.withValues(alpha: 0.24),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: palette.pageShadow.withValues(alpha: 0.06),
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimatedDiaryPageFrame extends StatelessWidget {
  const _AnimatedDiaryPageFrame({
    required this.controller,
    required this.index,
    required this.child,
  });

  final PageController controller;
  final int index;
  final Widget child;

  double _pageValue() {
    if (controller.hasClients && controller.position.haveDimensions) {
      return controller.page ?? controller.initialPage.toDouble();
    }
    return controller.initialPage.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).diary;
    const borderRadius = BorderRadius.all(
      Radius.circular(_pageFrameCornerRadius),
    );

    return AnimatedBuilder(
      animation: controller,
      child: child,
      builder: (context, child) {
        final delta = index - _pageValue();
        final clamped = delta.clamp(-1.0, 1.0).toDouble();
        final distance = clamped.abs();
        final rotationY = clamped * 0.08;
        final scale = 1 - (distance * 0.01);
        final translateX = clamped * 6;
        final translateY = distance * 2;
        final shadeStrength = 0.03 + (distance * 0.09);
        final leadingFromLeft = clamped > 0;

        return Transform.translate(
          offset: Offset(translateX, translateY),
          child: Transform(
            alignment: leadingFromLeft
                ? Alignment.centerLeft
                : Alignment.centerRight,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..scaleByDouble(scale, 1.0, 1.0, 1.0)
              ..rotateY(rotationY),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                boxShadow: [
                  BoxShadow(
                    color: palette.pageShadow.withValues(
                      alpha: 0.12 + ((1 - distance) * 0.08),
                    ),
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: borderRadius,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    child!,
                    IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: leadingFromLeft
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            end: leadingFromLeft
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            colors: [
                              Colors.white.withValues(
                                alpha: (1 - distance) * 0.05,
                              ),
                              Colors.black.withValues(alpha: shadeStrength),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: leadingFromLeft ? 0 : null,
                      right: leadingFromLeft ? null : 0,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: leadingFromLeft
                                  ? Alignment.centerLeft
                                  : Alignment.centerRight,
                              end: leadingFromLeft
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              colors: [
                                Colors.white.withValues(alpha: 0.16),
                                Colors.white.withValues(alpha: 0),
                              ],
                            ),
                          ),
                          child: const SizedBox(width: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
