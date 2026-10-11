import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/format/time_format.dart';
import 'package:rider_app/core/l10n/app_locales.dart';
import 'package:rider_app/core/l10n/l10n.dart';

/// The text without the direction marks around numbers.
String _plain(String text) => text.replaceAll(RegExp('[\u2066-\u2069]'), '');

void main() {
  final ar = lookupAppLocalizations(AppLocales.arabic);
  final en = lookupAppLocalizations(AppLocales.english);

  test('times are 12-hour with Western digits in every language', () {
    expect(_plain(formatClock(en, DateTime(2026, 1, 1, 0, 5))), '12:05 ${en.timeAm}');
    expect(_plain(formatClock(en, DateTime(2026, 1, 1, 13, 30))), '01:30 ${en.timePm}');
    expect(_plain(formatClock(ar, DateTime(2026, 1, 1, 8, 30))), '08:30 ${ar.timeAm}');
    expect(formatClock(ar, DateTime(2026, 1, 1, 8, 30)), isNot(contains('٠')));
  });

  test('days are today, tomorrow, then their name and date', () {
    final now = DateTime(2026, 10, 10, 22);

    expect(formatDay(ar, DateTime(2026, 10, 10, 23), now), ar.today);
    expect(formatDay(ar, DateTime(2026, 10, 11, 1), now), ar.tomorrow);
    expect(_plain(formatDay(ar, DateTime(2026, 10, 12), now)), '${ar.weekdayMonday} 12/10');
  });
}
