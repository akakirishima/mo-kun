import 'package:flutter/material.dart';
import 'package:gdgoc_2026_prototype/core/app/app_models.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/models/diary_book.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/widgets/diary_retro_components.dart';
import 'package:nes_ui/nes_ui.dart';

class DiaryShelfView extends StatelessWidget {
  const DiaryShelfView({
    super.key,
    required this.books,
    required this.onClose,
    required this.onSelectBook,
  });

  final List<DiaryShelfBook> books;
  final VoidCallback onClose;
  final ValueChanged<DiaryShelfBook> onSelectBook;

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).diary;

    return Column(
      key: const ValueKey<String>('diary-shelf-screen'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '本棚',
                      style: TextStyle(
                        fontFamily: 'NotoSansJP',
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: palette.titleText,
                        decoration: TextDecoration.none,
                        shadows: const [],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '記録した月の本を並べました',
                      style: TextStyle(
                        fontFamily: 'NotoSansJP',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: palette.bodyDetail.withValues(alpha: 0.78),
                        decoration: TextDecoration.none,
                        shadows: const [],
                      ),
                    ),
                  ],
                ),
              ),
              DiaryRetroPressable(
                key: const ValueKey<String>('diary-shelf-close-button'),
                fillColor: Colors.white.withValues(alpha: 0.18),
                borderColor: Colors.white.withValues(alpha: 0.42),
                shadowColor: palette.titleText.withValues(alpha: 0.12),
                width: 40,
                height: 40,
                padding: EdgeInsets.zero,
                onPress: onClose,
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: palette.paperFill,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: books.isEmpty
              ? Center(
                  child: Text(
                    'まだ記録された本はありません',
                    style: TextStyle(
                      fontFamily: 'NotoSansJP',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: palette.bodyDetail.withValues(alpha: 0.76),
                      decoration: TextDecoration.none,
                      shadows: const [],
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index];
                    return _ShelfBookTile(
                      book: book,
                      onTap: () => onSelectBook(book),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ShelfBookTile extends StatelessWidget {
  const _ShelfBookTile({required this.book, required this.onTap});

  final DiaryShelfBook book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).diary;
    final monthAccent = diaryMonthAccentColor(book.monthStart.month);
    final coverFill = Color.lerp(palette.coverFill, monthAccent, 0.4)!;
    final coverAccent = Color.lerp(
      palette.coverAccent,
      Color.lerp(monthAccent, Colors.white, 0.55)!,
      0.28,
    )!;
    final borderColor = Color.lerp(palette.titleText, monthAccent, 0.16)!;
    final shadowColor = Color.lerp(
      palette.spineShadow,
      monthAccent,
      0.22,
    )!.withValues(alpha: 0.18);

    return NesPressable(
      key: ValueKey<String>(
        'diary-shelf-book-${_shelfBookKey(book.monthStart)}',
      ),
      onPress: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [coverFill, coverAccent],
          ),
          border: Border.all(color: borderColor, width: 3),
          boxShadow: [
            BoxShadow(color: shadowColor, offset: const Offset(0, 6)),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: borderColor.withValues(alpha: 0.42),
              width: 2,
            ),
            color: Colors.white.withValues(alpha: 0.08),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 16,
                height: 92,
                decoration: BoxDecoration(
                  color: borderColor.withValues(alpha: 0.16),
                  border: Border.all(
                    color: borderColor.withValues(alpha: 0.22),
                    width: 2,
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(
                    Icons.auto_stories_rounded,
                    size: 18,
                    color: palette.paperFill.withValues(alpha: 0.92),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      book.monthLabel,
                      style: TextStyle(
                        fontFamily: 'NotoSansJP',
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: palette.titleText.withValues(alpha: 0.94),
                        decoration: TextDecoration.none,
                        shadows: const [],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${book.recordedDaysCount}日 記録あり',
                style: TextStyle(
                  fontFamily: 'NotoSansJP',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: palette.ink.withValues(alpha: 0.8),
                  decoration: TextDecoration.none,
                  shadows: const [],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _shelfBookKey(DateTime monthStart) {
  final month = monthStart.month.toString().padLeft(2, '0');
  return '${monthStart.year}-$month';
}
