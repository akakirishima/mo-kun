import 'package:flutter/material.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/models/diary_book.dart';

class DiaryInlineSelector extends StatelessWidget {
  const DiaryInlineSelector({
    super.key,
    required this.label,
    required this.onTap,
    required this.textColor,
    this.backgroundColor,
    this.borderColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.textStyle,
  });

  final String label;
  final VoidCallback onTap;
  final Color textColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(999),
      side: BorderSide(color: borderColor ?? Colors.transparent),
    );

    return Material(
      color: backgroundColor ?? Colors.transparent,
      shape: shape,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: Padding(
          padding: padding,
          child: Text(
            label,
            style:
                textStyle ??
                Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ),
    );
  }
}

class DiaryCardIconButton extends StatelessWidget {
  const DiaryCardIconButton({
    super.key,
    required this.onTap,
    required this.iconColor,
    required this.backgroundColor,
  });

  final VoidCallback onTap;
  final Color iconColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      child: InkWell(
        key: const ValueKey<String>('diary-settings-button'),
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(Icons.settings_outlined, size: 18, color: iconColor),
        ),
      ),
    );
  }
}

Future<int?> showDiaryDaySelectorSheet({
  required BuildContext context,
  required DiaryMonthBook book,
  required int selectedIndex,
}) {
  return showModalBottomSheet<int>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) {
      return DiaryDaySelectorSheet(book: book, selectedIndex: selectedIndex);
    },
  );
}

class DiaryDaySelectorSheet extends StatelessWidget {
  const DiaryDaySelectorSheet({
    super.key,
    required this.book,
    required this.selectedIndex,
  });

  final DiaryMonthBook book;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      key: const ValueKey<String>('diary-day-selector-sheet'),
      height: 460,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.monthLabel,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '表紙または日付を選んで、すぐにそのページへ移動します。',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: book.pageCount,
              itemBuilder: (context, index) {
                final entry = book.entryAt(index);
                final isSelected = selectedIndex == index;
                final title = entry == null
                    ? '表紙'
                    : '3月 ${entry.dayNumber}日 ${entry.weekdayLabel}ようび';
                final subtitle = entry == null
                    ? book.coverSubtitle
                    : entry.highlightLabel;

                return ListTile(
                  key: ValueKey<String>('diary-day-selector-page-$index'),
                  onTap: () => Navigator.of(context).pop(index),
                  leading: CircleAvatar(
                    backgroundColor: isSelected
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    child: Text(index == 0 ? '表' : '${entry!.dayNumber}'),
                  ),
                  title: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(subtitle),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: theme.colorScheme.primary,
                        )
                      : const Icon(Icons.chevron_right_rounded),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
