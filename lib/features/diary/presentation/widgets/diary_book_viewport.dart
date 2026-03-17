import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/models/diary_book.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/widgets/diary_cover_page.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/widgets/diary_day_page.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/widgets/diary_day_selector.dart';

class DiaryBookViewport extends StatelessWidget {
  const DiaryBookViewport({
    super.key,
    required this.book,
    required this.controller,
    required this.onPageChanged,
    required this.onOpenSelector,
    required this.onShowPreviousMonth,
    required this.onShowNextMonth,
    required this.onSettingsTap,
    required this.dayPageBottomClearance,
  });

  final DiaryMonthBook book;
  final PageController controller;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onOpenSelector;
  final VoidCallback onShowPreviousMonth;
  final VoidCallback onShowNextMonth;
  final VoidCallback onSettingsTap;
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
                  const Positioned.fill(child: _PageStackBackdrop()),
                  Positioned(
                    top: 8,
                    bottom: 8,
                    left: 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            palette.paperEdge.withValues(alpha: 0.55),
                            palette.paperEdge.withValues(alpha: 0.18),
                          ],
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
                  Positioned(
                    top: 12,
                    right: 10,
                    child: DiaryCardIconButton(
                      onTap: onSettingsTap,
                      iconColor: palette.ink.withValues(alpha: 0.78),
                      backgroundColor: palette.paperFill.withValues(
                        alpha: 0.88,
                      ),
                    ),
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
  const _PageStackBackdrop();

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).diary;

    return Stack(
      children: [
        Positioned(
          left: 8,
          right: 4,
          top: 8,
          bottom: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: palette.paperFill.withValues(alpha: 0.52),
              borderRadius: BorderRadius.circular(30),
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
              color: palette.paperFill.withValues(alpha: 0.34),
              borderRadius: BorderRadius.circular(30),
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
    const borderRadius = BorderRadius.all(Radius.circular(32));

    return AnimatedBuilder(
      animation: controller,
      child: child,
      builder: (context, child) {
        final delta = index - _pageValue();
        final clamped = delta.clamp(-1.0, 1.0).toDouble();
        final distance = clamped.abs();
        final rotationY = clamped * 0.22;
        final scale = 1 - (distance * 0.022);
        final translateX = clamped * 10;
        final translateY = distance * 3;
        final shadeStrength = 0.06 + (distance * 0.20);
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
                      alpha: 0.18 + ((1 - distance) * 0.18),
                    ),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
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
                                alpha: (1 - distance) * 0.12,
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
                                Colors.white.withValues(alpha: 0.24),
                                Colors.white.withValues(alpha: 0),
                              ],
                            ),
                          ),
                          child: const SizedBox(width: 18),
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
