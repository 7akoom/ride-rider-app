/// A voucher's code as the rider types or pastes it: sixteen letters and digits,
/// printed in fours (ABCD-EFGH-JKMN-PQRS). Spaces, dashes and case do not matter;
/// the letters and digits that look alike (0/O, 1/I/L) are never in a code.
abstract final class VoucherCode {
  static const int length = 16;

  /// How a code is printed; the field's hint.
  static const String example = 'XXXX-XXXX-XXXX-XXXX';

  static const String _alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  /// [typed] without spaces and dashes, in capitals; null when it holds a character
  /// no code has. The same rule as the wallet service.
  static String? clean(String typed) {
    final out = StringBuffer();

    for (final char in typed.toUpperCase().split('')) {
      if (char == ' ' || char == '-' || char == '\t') {
        continue;
      }
      if (!_alphabet.contains(char)) {
        return null;
      }
      out.write(char);
    }

    return out.toString();
  }

  /// True when [typed] is a whole code.
  static bool isComplete(String typed) => clean(typed)?.length == length;

  /// True when [typed] can no longer become a code: a character no code has, or too long.
  static bool isWrong(String typed) {
    final code = clean(typed);

    return code == null || code.length > length;
  }
}
