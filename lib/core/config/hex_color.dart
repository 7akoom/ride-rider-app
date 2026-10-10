/// Reads a colour written as `#RRGGBB` or `RRGGBB` and returns it as an opaque ARGB
/// integer, or null when the text is not such a colour.
int? parseHexColor(String text) {
  final hex = text.trim().replaceFirst('#', '');

  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) {
    return null;
  }

  return 0xFF000000 | int.parse(hex, radix: 16);
}
