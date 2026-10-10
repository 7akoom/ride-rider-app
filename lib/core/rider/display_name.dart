/// Why a typed name cannot be used.
enum DisplayNameProblem { tooShort, tooLong }

/// The name captains and support see, checked: trimmed, inner spaces collapsed, between
/// [minLength] and [maxLength] letters (the backend accepts up to 120).
final class DisplayName {
  const DisplayName._(this.value);

  final String value;

  static const int minLength = 2;
  static const int maxLength = 60;

  /// What is wrong with [input], or null when it is a usable name.
  static DisplayNameProblem? check(String input) {
    final length = _clean(input).runes.length;

    if (length < minLength) {
      return DisplayNameProblem.tooShort;
    }

    return length > maxLength ? DisplayNameProblem.tooLong : null;
  }

  static DisplayName? tryParse(String input) =>
      check(input) == null ? DisplayName._(_clean(input)) : null;

  static String _clean(String input) => input.trim().split(RegExp(r'\s+')).join(' ');
}
