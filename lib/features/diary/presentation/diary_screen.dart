import 'package:flutter/material.dart';
import 'package:gdgoc_2026_prototype/app/shell/widgets/glass_bottom_dock.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/fixtures/diary_demo_book.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/models/diary_book.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/widgets/diary_book_viewport.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/widgets/diary_day_selector.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key, required this.onSettingsTap});

  final VoidCallback onSettingsTap;

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final DiaryMonthBook _book = demoMarchDiaryBook;
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

  Future<void> _openDaySelector() async {
    final selectedPage = await showDiaryDaySelectorSheet(
      context: context,
      book: _book,
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
                  book: _book,
                  controller: _pageController,
                  dayPageBottomClearance:
                      GlassBottomDock.reservedBottomSpacing - 12,
                  onOpenSelector: _openDaySelector,
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
