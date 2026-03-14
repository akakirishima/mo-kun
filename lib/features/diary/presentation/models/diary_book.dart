import 'package:flutter/material.dart';

enum DiaryBookPageKind { cover, entry }

class DiaryMonthBook {
  const DiaryMonthBook({
    required this.monthLabel,
    required this.coverTitle,
    required this.coverSubtitle,
    required this.entries,
  });

  final String monthLabel;
  final String coverTitle;
  final String coverSubtitle;
  final List<DiaryDayEntry> entries;

  int get pageCount => entries.length + 1;

  DiaryBookPageKind pageKindAt(int index) {
    return index == 0 ? DiaryBookPageKind.cover : DiaryBookPageKind.entry;
  }

  DiaryDayEntry? entryAt(int index) {
    if (index == 0) {
      return null;
    }
    return entries[index - 1];
  }

  String pageLabelAt(int index) {
    final entry = entryAt(index);
    if (entry == null) {
      return '$monthLabel 表紙';
    }
    return '${entry.dayNumber}日 ${entry.weekdayLabel}ようび';
  }
}

class DiaryDayEntry {
  const DiaryDayEntry({
    required this.dayNumber,
    required this.weekdayLabel,
    required this.body,
    required this.illustrationPalette,
    required this.highlightLabel,
  });

  final int dayNumber;
  final String weekdayLabel;
  final String body;
  final List<Color> illustrationPalette;
  final String highlightLabel;
}
