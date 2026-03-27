import 'package:flutter/material.dart';

enum DiaryBookPageKind { cover, entry }

const _diaryMonthAccentColors = <Color>[
  Color(0xFFB9D7F2),
  Color(0xFFE8ABC9),
  Color(0xFFF1B4CC),
  Color(0xFFF1C08E),
  Color(0xFFA8D59E),
  Color(0xFFAAB8F3),
  Color(0xFF8DCAE8),
  Color(0xFFF0C46C),
  Color(0xFFC6A8E5),
  Color(0xFFE0A16E),
  Color(0xFF9FB67B),
  Color(0xFFBDD9E9),
];

Color diaryMonthAccentColor(int month) {
  final index = ((month - 1) % 12 + 12) % 12;
  return _diaryMonthAccentColors[index];
}

class DiaryMonthCalendar {
  const DiaryMonthCalendar({
    required this.monthStart,
    required this.dayCount,
    required this.leadingBlankCount,
    required this.recordedDays,
    required this.todayDayNumber,
  });

  final DateTime monthStart;
  final int dayCount;
  final int leadingBlankCount;
  final Set<int> recordedDays;
  final int? todayDayNumber;

  List<int?> get daySlots {
    final filledDays = <int?>[
      ...List<int?>.filled(leadingBlankCount, null),
      ...List<int?>.generate(dayCount, (index) => index + 1),
    ];
    final trailingBlankCount = 42 - filledDays.length;
    return [...filledDays, ...List<int?>.filled(trailingBlankCount, null)];
  }

  bool isRecordedDay(int dayNumber) => recordedDays.contains(dayNumber);

  bool isToday(int dayNumber) => todayDayNumber == dayNumber;
}

class DiaryMonthBook {
  const DiaryMonthBook({
    required this.monthLabel,
    required this.coverTitle,
    required this.coverSubtitle,
    required this.calendar,
    required this.canShowPreviousMonth,
    required this.canShowNextMonth,
    required this.entries,
  });

  final String monthLabel;
  final String coverTitle;
  final String coverSubtitle;
  final DiaryMonthCalendar calendar;
  final bool canShowPreviousMonth;
  final bool canShowNextMonth;
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

  int? pageIndexForDay(int dayNumber) {
    final entryIndex = entries.indexWhere(
      (entry) => entry.dayNumber == dayNumber,
    );
    if (entryIndex == -1) {
      return null;
    }
    return entryIndex + 1;
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
    this.imageUrl,
  });

  final int dayNumber;
  final String weekdayLabel;
  final String body;
  final List<Color> illustrationPalette;
  final String highlightLabel;
  final String? imageUrl;
}
