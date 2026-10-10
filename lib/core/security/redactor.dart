/// Removes secrets and personal data from text before it is logged.
///
/// Logs never carry tokens, phone numbers or e-mail addresses, even in debug builds,
/// because debug logs end up in bug reports and screenshots.
abstract final class Redactor {
  static final List<(RegExp, String)> _rules = [
    // Authorization headers and bare bearer tokens.
    (RegExp(r'Bearer\s+[A-Za-z0-9\-._~+/]+=*', caseSensitive: false), 'Bearer ***'),
    // JWTs (three base64url parts).
    (RegExp(r'eyJ[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+'), '***jwt***'),
    // Token-like JSON fields.
    (
      RegExp(r'"(accessToken|refreshToken|token|pin|code|password)"\s*:\s*"[^"]*"',
          caseSensitive: false),
      r'"$1":"***"',
    ),
    // E-mail addresses.
    (RegExp(r'[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}'), '***@***'),
    // Phone numbers: 7 or more digits, optionally with a leading + and separators.
    (RegExp(r'\+?\d[\d\s\-]{6,}\d'), '***phone***'),
  ];

  static String redact(String input) {
    var output = input;

    for (final (pattern, replacement) in _rules) {
      output = output.replaceAllMapped(pattern, (match) {
        if (!replacement.contains(r'$1')) {
          return replacement;
        }

        return replacement.replaceAll(r'$1', match.group(1) ?? '');
      });
    }

    return output;
  }
}
