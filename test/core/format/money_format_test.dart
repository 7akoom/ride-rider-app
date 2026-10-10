import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/format/money_format.dart';
import 'package:rider_app/core/l10n/app_locales.dart';
import 'package:rider_app/core/l10n/l10n.dart';

void main() {
  test('amounts use thousands separators and Western digits', () {
    expect(formatAmount(0), '0');
    expect(formatAmount(3000), '3,000');
    expect(formatAmount(1250000), '1,250,000');
  });

  test('signs', () {
    expect(formatAmount(-2700), '-2,700');
    expect(formatAmount(2700, signed: true), '+2,700');
    expect(formatAmount(0, signed: true), '0');
  });

  test('money is the isolated number plus the currency of the language', () {
    final english = lookupAppLocalizations(AppLocales.english);
    final arabic = lookupAppLocalizations(AppLocales.arabic);

    expect(formatMoney(english, 3000), '\u20663,000\u2069 IQD');
    expect(formatMoney(arabic, -500), arabic.moneyAmount('\u2066-500\u2069'));
  });
}
