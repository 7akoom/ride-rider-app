import '../l10n/l10n.dart';
import 'bidi.dart';

/// "08:30 AM" in the rider's language (its own AM and PM), Western digits, 12-hour.
String formatClock(AppLocalizations l10n, DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final digits = '${_two(hour)}:${_two(time.minute)}';

  return '${isolateLtr(digits)} ${time.hour < 12 ? l10n.timeAm : l10n.timePm}';
}

/// The day's name in the rider's language, Monday to Sunday.
String weekdayName(AppLocalizations l10n, DateTime day) => switch (day.weekday) {
      DateTime.monday => l10n.weekdayMonday,
      DateTime.tuesday => l10n.weekdayTuesday,
      DateTime.wednesday => l10n.weekdayWednesday,
      DateTime.thursday => l10n.weekdayThursday,
      DateTime.friday => l10n.weekdayFriday,
      DateTime.saturday => l10n.weekdaySaturday,
      _ => l10n.weekdaySunday,
    };

/// "Today", "Tomorrow", then "Saturday 12/10" for the days after.
String formatDay(AppLocalizations l10n, DateTime day, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(day.year, day.month, day.day);

  return switch (date.difference(today).inDays) {
    0 => l10n.today,
    1 => l10n.tomorrow,
    _ => formatDate(l10n, date),
  };
}

/// "Saturday 12/10": the day's name and its date, Western digits.
String formatDate(AppLocalizations l10n, DateTime day) =>
    '${weekdayName(l10n, day)} ${isolateLtr('${day.day}/${day.month}')}';

String _two(int value) => value.toString().padLeft(2, '0');
