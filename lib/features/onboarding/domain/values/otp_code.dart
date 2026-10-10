import '../../../../core/format/digits.dart';

/// A login code as typed: exactly [length] digits, in any of the digit sets Arabic
/// and Kurdish keyboards use.
final class OtpCode {
  const OtpCode._(this.digits);

  /// The code in Western digits, as the backend wants it.
  final String digits;

  static const int length = 6;

  static OtpCode? tryParse(String input) {
    final digits = westernDigitsOnly(input);

    return digits.length == length ? OtpCode._(digits) : null;
  }
}
