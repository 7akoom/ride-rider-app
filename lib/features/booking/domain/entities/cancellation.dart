/// Why the rider cancels a ride a captain took.
enum CancelReason { captainLate, changedMind, orderedByMistake, captainAsked, other }

/// The rider's reason, with their own words for [CancelReason.other].
final class Cancellation {
  const Cancellation(this.reason, [this.text = '']);

  final CancelReason reason;
  final String text;

  /// The most the rider may write.
  static const int maxText = 200;

  /// The reason as given, or null when "other" comes without words.
  static Cancellation? of(CancelReason reason, String text) {
    final words = text.trim();

    if (reason == CancelReason.other && words.isEmpty) {
      return null;
    }

    return Cancellation(
      reason,
      reason == CancelReason.other
          ? (words.length > maxText ? words.substring(0, maxText) : words)
          : '',
    );
  }
}
