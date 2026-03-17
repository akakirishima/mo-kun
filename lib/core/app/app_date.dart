const int _jstOffsetHours = 9;
const int _appDayCutoffHours = 3;

DateTime resolveAppDate(DateTime dateTime) {
  final shifted = dateTime.toUtc().add(
    const Duration(hours: _jstOffsetHours - _appDayCutoffHours),
  );
  return DateTime(shifted.year, shifted.month, shifted.day);
}

String buildAppDateKeyFromDateTime(DateTime dateTime) {
  final appDate = resolveAppDate(dateTime);
  final month = appDate.month.toString().padLeft(2, '0');
  final day = appDate.day.toString().padLeft(2, '0');
  return '${appDate.year}-$month-$day';
}

DateTime? parseDateKey(String dateKey) {
  final parts = dateKey.split('-');
  if (parts.length != 3) {
    return null;
  }

  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) {
    return null;
  }
  return DateTime(year, month, day);
}

DateTime appMonthStart(DateTime monthLike) {
  return DateTime(monthLike.year, monthLike.month);
}

DateTime previousMonth(DateTime monthLike) {
  return DateTime(monthLike.year, monthLike.month - 1);
}

DateTime nextMonth(DateTime monthLike) {
  return DateTime(monthLike.year, monthLike.month + 1);
}

DateTime appDayBoundaryUtc(DateTime appDate) {
  return DateTime.utc(
    appDate.year,
    appDate.month,
    appDate.day,
    3 - _jstOffsetHours,
  );
}

String monthKey(DateTime monthLike) {
  final normalized = appMonthStart(monthLike);
  final month = normalized.month.toString().padLeft(2, '0');
  return '${normalized.year}-$month-';
}
