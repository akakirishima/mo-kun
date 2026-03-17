import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdgoc_2026_prototype/app/shell/widgets/glass_bottom_dock.dart';
import 'package:gdgoc_2026_prototype/core/app/app_date.dart';
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
    final result = await showDiaryDaySelectorSheet(
      context: context,
      book: book,
      selectedIndex: _currentPage,
    );
    if (!mounted || result == null) {
      return;
    }

    switch (result.action) {
      case DiarySelectorAction.previousMonth:
        _showPreviousMonth();
        return;
      case DiarySelectorAction.nextMonth:
        _showNextMonth();
        return;
      case null:
        break;
    }

    final selectedPage = result.pageIndex;
    if (selectedPage == null || selectedPage == _currentPage) {
      return;
    }
    await _pageController.animateToPage(
      selectedPage,
      duration: const Duration(milliseconds: 440),
      curve: Curves.easeOutCubic,
    );
  }

  void _setMonth(DateTime month) {
    ref.read(diaryMonthNavigationControllerProvider).setMonth(month);
    _pageController.jumpToPage(0);
    if (_currentPage != 0) {
      setState(() {
        _currentPage = 0;
      });
    }
  }

  void _showPreviousMonth() {
    final selectedMonth = ref.read(selectedDiaryMonthProvider);
    _setMonth(previousMonth(selectedMonth));
  }

  void _showNextMonth() {
    final navigation = ref.read(diaryMonthNavigationControllerProvider);
    if (!navigation.canShowNextMonth) {
      return;
    }
    _setMonth(nextMonth(navigation.selectedMonth));
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).diary;
    final appDate = ref.watch(currentAppDateProvider);
    final selectedMonth = ref.watch(selectedDiaryMonthProvider);
    final session = ref.watch(sessionProvider).valueOrNull;
    final summaries = session == null
        ? const <DailySummary>[]
        : (ref.watch(monthlyDailySummariesProvider(session)).valueOrNull ??
              const <DailySummary>[]);
    final images = session == null
        ? const <CharacterImageVersion>[]
        : (ref.watch(diaryImageHistoryProvider(session)).valueOrNull ??
              const <CharacterImageVersion>[]);
    final currentMonth = ref.watch(currentDiaryMonthProvider);
    final book = _buildDiaryBook(
      appDate: appDate,
      selectedMonth: selectedMonth,
      currentMonth: currentMonth,
      summaries: summaries,
      images: images,
    );

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
                  onShowPreviousMonth: _showPreviousMonth,
                  onShowNextMonth: _showNextMonth,
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

DiaryMonthBook _buildDiaryBook({
  required DateTime appDate,
  required DateTime selectedMonth,
  required DateTime currentMonth,
  required List<DailySummary> summaries,
  required List<CharacterImageVersion> images,
}) {
  final normalizedMonth = appMonthStart(selectedMonth);
  final sortedSummaries = [...summaries]
    ..sort((left, right) => left.dateKey.compareTo(right.dateKey));
  final latestSummary = sortedSummaries.isEmpty ? null : sortedSummaries.last;
  final sortedImages = [...images]
    ..sort((left, right) => left.generatedAt.compareTo(right.generatedAt));

  final entries = sortedSummaries.map((summary) {
    final date = parseDateKey(summary.dateKey) ??
        DateTime(normalizedMonth.year, normalizedMonth.month, 1);
    final isCurrentDay = _isSameDay(date, appDate);
    final image = _resolveImageForDate(sortedImages, summary.dateKey);

    final body = [
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
      illustrationPalette: _illustrationPaletteForEntry(
        isCurrentDay: isCurrentDay,
        hasSummary: true,
        isFutureDay: false,
      ),
      highlightLabel: summary.title,
      imageUrl: image?.imageUrl,
    );
  }).toList(growable: false);

  return DiaryMonthBook(
    monthLabel: '${normalizedMonth.month}月',
    coverTitle: 'AI Diary',
    coverSubtitle: _coverSubtitle(
      appDate: normalizedMonth,
      latestSummary: latestSummary,
    ),
    recordedDaysCount: summaries.length,
    canShowPreviousMonth: true,
    canShowNextMonth: normalizedMonth.isBefore(appMonthStart(currentMonth)),
    entries: entries,
  );
}

List<Color> _illustrationPaletteForEntry({
  required bool isCurrentDay,
  required bool hasSummary,
  required bool isFutureDay,
}) {
  if (isCurrentDay && hasSummary) {
    return const [Color(0xFFEFC7A9), Color(0xFFDE8F73), Color(0xFFF9E4A6)];
  }
  if (hasSummary) {
    return const [Color(0xFFEBD6C6), Color(0xFFD69A80), Color(0xFFF6E0A4)];
  }
  if (isFutureDay) {
    return const [Color(0xFFF4EBDD), Color(0xFFEADCC8), Color(0xFFF9F0CF)];
  }
  return const [Color(0xFFF4D8C5), Color(0xFFE7BFA5), Color(0xFFF8E8B2)];
}

String _coverSubtitle({
  required DateTime appDate,
  required DailySummary? latestSummary,
}) {
  if (latestSummary == null) {
    return '会話から1日ごとの記録を少しずつためていきます';
  }
  final latestDate = parseDateKey(latestSummary.dateKey);
  if (latestDate == null || latestDate.month == appDate.month) {
    return latestSummary.title;
  }
  return '${latestDate.month}月${latestDate.day}日までの記録を見返せます';
}

bool _isSameDay(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

String _dateKey(DateTime date) {
  return buildAppDateKeyFromDateTime(date);
}

CharacterImageVersion? _resolveImageForDate(
  List<CharacterImageVersion> images,
  String dateKey,
) {
  CharacterImageVersion? candidate;
  for (final image in images) {
    final imageDateKey =
        image.dateKey ?? buildAppDateKeyFromDateTime(image.generatedAt);
    if (imageDateKey.compareTo(dateKey) > 0) {
      break;
    }
    if ((image.imageUrl ?? '').isEmpty) {
      continue;
    }
    candidate = image;
  }
  return candidate;
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
