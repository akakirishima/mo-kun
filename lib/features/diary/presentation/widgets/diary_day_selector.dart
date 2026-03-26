import 'package:flutter/material.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/models/diary_book.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/widgets/diary_retro_components.dart';

enum DiarySelectorAction { previousMonth, nextMonth }

class DiarySelectorResult {
  const DiarySelectorResult.page(this.pageIndex) : action = null;
  const DiarySelectorResult.action(this.action) : pageIndex = null;

  final int? pageIndex;
  final DiarySelectorAction? action;
}

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
  final EdgeInsets padding;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final effectiveBorder = borderColor ?? Colors.transparent;
    final effectiveBackground = backgroundColor ?? Colors.transparent;
    return DiaryRetroPressable(
      fillColor: effectiveBackground,
      borderColor: effectiveBorder,
      onPress: onTap,
      padding: padding,
      shadowColor: effectiveBorder.withValues(alpha: 0.2),
      child: Text(
        label,
        style:
            textStyle ??
            Theme.of(context).textTheme.labelLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

Future<DiarySelectorResult?> showDiaryDaySelectorSheet({
  required BuildContext context,
  required DiaryMonthBook book,
  required int selectedIndex,
}) {
  return showModalBottomSheet<DiarySelectorResult>(
    context: context,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
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
    final palette = AppearanceScope.paletteOf(context).diary;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
      child: SizedBox(
        key: const ValueKey<String>('diary-day-selector-sheet'),
        height: 470,
        child: DiaryRetroPanel(
          fillColor: palette.cardFill,
          borderColor: palette.paperEdge.withValues(alpha: 0.95),
          innerBorderColor: palette.ruleLine.withValues(alpha: 0.88),
          shadowColor: palette.pageShadow.withValues(alpha: 0.18),
          accentColor: palette.coverAccent,
          radius: 26,
          innerRadius: 20,
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
          textureOpacity: 0.045,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: palette.ruleLine.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _SelectorMonthButton(
                    widgetKey: const ValueKey<String>(
                      'diary-selector-previous-month',
                    ),
                    icon: Icons.chevron_left_rounded,
                    tooltip: '前の月',
                    enabled: book.canShowPreviousMonth,
                    onTap: () => Navigator.of(context).pop(
                      const DiarySelectorResult.action(
                        DiarySelectorAction.previousMonth,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          book.monthLabel,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: palette.titleText,
                            fontFamily: 'NotoSerifJP',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '表紙または日付を選んで、そのページをひらきます。',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: palette.bodyDetail,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _SelectorMonthButton(
                    widgetKey: const ValueKey<String>(
                      'diary-selector-next-month',
                    ),
                    icon: Icons.chevron_right_rounded,
                    tooltip: '次の月',
                    enabled: book.canShowNextMonth,
                    onTap: () => Navigator.of(context).pop(
                      const DiarySelectorResult.action(
                        DiarySelectorAction.nextMonth,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: book.pageCount,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final entry = book.entryAt(index);
                    final isSelected = selectedIndex == index;
                    final title = entry == null
                        ? '表紙'
                        : '${book.monthLabel} ${entry.dayNumber}日 ${entry.weekdayLabel}ようび';
                    final subtitle = entry == null
                        ? book.coverSubtitle
                        : entry.highlightLabel;

                    return _SelectorEntryCard(
                      tileKey: ValueKey<String>(
                        'diary-day-selector-page-$index',
                      ),
                      selected: isSelected,
                      label: index == 0 ? '表' : '${entry!.dayNumber}',
                      title: title,
                      subtitle: subtitle,
                      onTap: () => Navigator.of(
                        context,
                      ).pop(DiarySelectorResult.page(index)),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectorEntryCard extends StatelessWidget {
  const _SelectorEntryCard({
    required this.tileKey,
    required this.selected,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Key tileKey;
  final bool selected;
  final String label;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).diary;
    final fillColor = selected
        ? palette.coverAccent.withValues(alpha: 0.78)
        : palette.paperFill.withValues(alpha: 0.98);
    final borderColor = selected
        ? palette.coverFill.withValues(alpha: 0.95)
        : palette.paperEdge.withValues(alpha: 0.95);
    final shadowColor = selected
        ? palette.coverFill.withValues(alpha: 0.2)
        : palette.pageShadow.withValues(alpha: 0.12);

    return DiaryRetroPressable(
      key: tileKey,
      fillColor: fillColor,
      borderColor: borderColor,
      onPress: onTap,
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      shadowColor: shadowColor,
      child: Row(
        children: [
          DiaryRetroPanel(
            fillColor: Colors.white.withValues(alpha: 0.6),
            borderColor: palette.ruleLine.withValues(alpha: 0.95),
            innerBorderColor: palette.ruleLine.withValues(alpha: 0.72),
            shadowColor: palette.paperEdge.withValues(alpha: 0.2),
            padding: EdgeInsets.zero,
            textureOpacity: 0,
            child: SizedBox(
              width: 42,
              height: 42,
              child: Center(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: palette.titleText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: palette.cardTitle,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: palette.bodyDetail,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            selected ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
            color: selected ? palette.coverFill : palette.settingsIcon,
          ),
        ],
      ),
    );
  }
}

class _SelectorMonthButton extends StatelessWidget {
  const _SelectorMonthButton({
    required this.widgetKey,
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
  });

  final Key widgetKey;
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).diary;

    return Tooltip(
      message: tooltip,
      child: DiaryRetroPressable(
        key: widgetKey,
        fillColor: enabled
            ? palette.paperFill.withValues(alpha: 0.98)
            : palette.paperFill.withValues(alpha: 0.55),
        borderColor: palette.paperEdge.withValues(alpha: 0.95),
        onPress: enabled ? onTap : null,
        disabled: !enabled,
        width: 42,
        height: 42,
        padding: EdgeInsets.zero,
        shadowColor: palette.paperEdge.withValues(alpha: 0.24),
        child: Icon(icon, color: palette.settingsIcon),
      ),
    );
  }
}
