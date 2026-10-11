/// What became of the coupon code the rider entered, for one ride type.
enum CouponResult {
  none,
  applied,
  notFound,
  ended,
  notStarted,
  expired,
  usedUp,
  alreadyUsed,
  notInArea,
  notForClass,
  newRidersOnly,
  belowMinimum,

  /// The coupon is fine, but a bigger discount (first ride, loyalty) applies instead.
  betterDiscount,
}

/// Which discount lowered the price. One at most: the server never stacks them.
enum DiscountKind {
  none,
  firstRide,
  loyalty,
  coupon,

  /// A discount this version of the app has no name for.
  other,
}

/// The fixed price of one ride type for the trip. Requesting the trip with it keeps the
/// price, until [expiresAt].
final class FareQuote {
  const FareQuote({
    required this.id,
    required this.vehicleClass,
    required this.total,
    required this.expiresAt,
    this.beforeDiscount,
    this.driversAvailable = false,
    this.pickupEtaMinutes = 0,
    this.surging = false,
    this.coupon = CouponResult.none,
    this.discount = DiscountKind.none,
  });

  final String id;

  /// economy or comfort.
  final String vehicleClass;

  /// Whole currency units.
  final int total;

  /// The price without the discount, when one applies.
  final int? beforeDiscount;
  final DateTime expiresAt;

  /// A free captain of this type is near the pickup now.
  final bool driversAvailable;

  /// How far the nearest one is (0 when unknown).
  final int pickupEtaMinutes;

  /// Demand is high: the price includes a surge.
  final bool surging;
  final CouponResult coupon;

  /// Why the price is lower than [beforeDiscount].
  final DiscountKind discount;

  bool isExpiredAt(DateTime now) => !now.isBefore(expiresAt);
}

/// The prices of every ride type for one trip, cheapest first.
final class FareQuotes {
  const FareQuotes(this.quotes);

  final List<FareQuote> quotes;

  bool get surging => quotes.any((quote) => quote.surging);

  /// The first moment one of the prices stops being valid.
  DateTime? get expiresAt {
    DateTime? earliest;

    for (final quote in quotes) {
      if (earliest == null || quote.expiresAt.isBefore(earliest)) {
        earliest = quote.expiresAt;
      }
    }

    return earliest;
  }

  FareQuote? ofClass(String? vehicleClass) {
    for (final quote in quotes) {
      if (quote.vehicleClass == vehicleClass) {
        return quote;
      }
    }

    return null;
  }
}
