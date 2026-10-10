import 'package:intl/intl.dart';

import '../l10n/l10n.dart';

const String _ltrIsolate = '\u2066';
const String _popIsolate = '\u2069';

final NumberFormat _grouped = NumberFormat.decimalPattern('en');

/// A whole amount with thousands separators and Western digits, in every language
/// (the design keeps digits Western everywhere): 3000 -> "3,000".
///
/// [signed] adds "+" before positive amounts (wallet credits); negative amounts always
/// get "-".
String formatAmount(int amount, {bool signed = false}) {
  final digits = _grouped.format(amount.abs());

  if (amount < 0) {
    return '-$digits';
  }

  return signed && amount > 0 ? '+$digits' : digits;
}

/// An amount with the currency, in the rider's language ("3,000 IQD" in English).
///
/// The number is isolated as left-to-right text, so a sign and separators keep their
/// place inside Arabic and Kurdish sentences.
String formatMoney(AppLocalizations l10n, int amount, {bool signed = false}) {
  final number = formatAmount(amount, signed: signed);

  return l10n.moneyAmount('$_ltrIsolate$number$_popIsolate');
}
