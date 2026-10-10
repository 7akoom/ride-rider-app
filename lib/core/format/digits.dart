/// Keeps only the digits of [input], as Western digits (0-9).
///
/// Arabic-Indic (U+0660-U+0669) and Persian (U+06F0-U+06F9) digits are converted, since
/// Arabic and Kurdish keyboards type them; everything else (spaces, dashes, brackets,
/// letters) is dropped.
String westernDigitsOnly(String input) {
  final buffer = StringBuffer();

  for (final rune in input.runes) {
    if (rune >= 0x30 && rune <= 0x39) {
      buffer.writeCharCode(rune);
    } else if (rune >= 0x0660 && rune <= 0x0669) {
      buffer.writeCharCode(0x30 + (rune - 0x0660));
    } else if (rune >= 0x06F0 && rune <= 0x06F9) {
      buffer.writeCharCode(0x30 + (rune - 0x06F0));
    }
  }

  return buffer.toString();
}
