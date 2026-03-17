import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdgoc_2026_prototype/app/shell/widgets/glass_bottom_dock.dart';
import 'package:gdgoc_2026_prototype/core/app/app_models.dart';
import 'package:gdgoc_2026_prototype/core/app/app_providers.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/models/diary_book.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/widgets/diary_book_viewport.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/widgets/diary_day_selector.dart';

class DiaryScreen extends ConsumerStatefulWidget {
  const DiaryScreen({super.key, required this.onSettingsTap});

  final VoidCallback onSettingsTap;

  @override
  ConsumerState<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends ConsumerState<DiaryScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.992);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openDaySelector(DiaryMonthBook book) async {
    final selectedPage = await showDiaryDaySelectorSheet(
      context: context,
      book: book,
      selectedIndex: _currentPage,
    );
    if (!mounted || selectedPage == null || selectedPage == _currentPage) {
      return;
    }
    await _pageController.animateToPage(
      selectedPage,
      duration: const Duration(milliseconds: 440),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).diary;
    final session = ref.watch(sessionProvider).valueOrNull;
    final summary = session == null
        ? null
        : ref.watch(dailySummaryProvider(session)).valueOrNull;
    final book = _buildDiaryBook(summary);

    return DecoratedBox(
      key: const ValueKey<String>('diary-background'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.backgroundTop, palette.backgroundBottom],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -30,
            child: _BackdropGlow(
              size: 220,
              color: palette.coverAccent.withValues(alpha: 0.34),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
              child: SizedBox.expand(
                key: const ValueKey<String>('diary-screen'),
                child: DiaryBookViewport(
                  book: book,
                  controller: _pageController,
                  dayPageBottomClearance:
                      GlassBottomDock.reservedBottomSpacing - 12,
                  onOpenSelector: () => _openDaySelector(book),
                  onSettingsTap: widget.onSettingsTap,
                  onPageChanged: (index) {
                    if (_currentPage == index) {
                      return;
                    }
                    setState(() {
                      _currentPage = index;
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

DiaryMonthBook _buildDiaryBook(DailySummary? summary) {
  final now = DateTime.now();
  final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
  final entries = List<DiaryDayEntry>.generate(daysInMonth, (index) {
    final date = DateTime(now.year, now.month, index + 1);
    final isCurrentDay = date.day == now.day;
    final body = !isCurrentDay || summary == null
        ? 'まだ今日の会話要約はありません。Homeで報告すると、ここに1日のまとめが並びます。'
        : [
            summary.title,
            '',
            '気分: ${summary.mood}',
            '',
            'できたこと',
            if (summary.doneThings.isEmpty)
              '・まだ記録がありません'
            else
              ...summary.doneThings.map((item) => '・$item'),
            '',
            '振り返り',
            summary.reflection,
            '',
            '明日のひとこと',
            summary.tomorrowNote,
          ].join('\n');
    return DiaryDayEntry(
      dayNumber: date.day,
      weekdayLabel: _weekdayLabel(date.weekday),
      body: body,
      illustrationPalette: isCurrentDay
          ? const [Color(0xFFEFC7A9), Color(0xFFDE8F73), Color(0xFFF9E4A6)]
          : const [Color(0xFFF4D8C5), Color(0xFFE7BFA5), Color(0xFFF8E8B2)],
      highlightLabel: isCurrentDay && summary != null ? summary.title : '準備中',
    );
  });

  return DiaryMonthBook(
    monthLabel: '${now.month}月',
    coverTitle: 'AI Diary',
    coverSubtitle: summary?.title ?? '今日の会話から1日を自動でまとめます',
    entries: entries,
  );
}

String _weekdayLabel(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return 'げつ';
    case DateTime.tuesday:
      return 'か';
    case DateTime.wednesday:
      return 'すい';
    case DateTime.thursday:
      return 'もく';
    case DateTime.friday:
      return 'きん';
    case DateTime.saturday:
      return 'ど';
    default:
      return 'にち';
  }
}

class _BackdropGlow extends StatelessWidget {
  const _BackdropGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
