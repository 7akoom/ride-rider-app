import '../format/digits.dart';

/// An Iraqi mobile number, checked and in international form (+9647XXXXXXXXX).
///
/// Only [tryParse] makes one, so holding a [PhoneNumber] means the number is valid.
final class PhoneNumber {
  const PhoneNumber._(this.e164);

  /// The number as the backend wants it, for example +9647701234567.
  final String e164;

  /// The ten digits after the country code (7701234567).
  String get national => e164.substring(_countryCode.length + 1);

  static const String _countryCode = '964';
  static const int _nationalLength = 10;

  /// Reads what a person typed, or returns null if it cannot be an Iraqi mobile number.
  ///
  /// Accepts Arabic-Indic and Persian digits, spaces, dashes and brackets, a leading 0
  /// (07701234567), and a leading 964, 00964 or +964.
  static PhoneNumber? tryParse(String input) {
    var digits = westernDigitsOnly(input);

    if (digits.startsWith('00$_countryCode')) {
      digits = digits.substring(2 + _countryCode.length);
    } else if (digits.startsWith(_countryCode)) {
      digits = digits.substring(_countryCode.length);
    }

    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    // Iraqi mobile numbers are ten digits starting with 7.
    if (digits.length != _nationalLength || !digits.startsWith('7')) {
      return null;
    }

    return PhoneNumber._('+$_countryCode$digits');
  }

  @override
  bool operator ==(Object other) => other is PhoneNumber && other.e164 == e164;

  @override
  int get hashCode => e164.hashCode;
}
