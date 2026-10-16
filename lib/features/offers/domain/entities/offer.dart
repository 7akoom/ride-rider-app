/// A percentage off (with an optional cap) or an amount off.
enum OfferDiscount { percent, amount }

/// A coupon the rider may use, as the server shows it to riders. Amounts are whole
/// currency units.
final class CouponOffer {
  const CouponOffer({
    required this.code,
    required this.kind,
    required this.value,
    required this.validUntil,
    this.description = '',
    this.maxDiscount,
    this.minimumFare = 0,
    this.vehicleClasses = const [],
    this.limitedArea = false,
    this.usesLeft = 1,
    this.newRidersOnly = false,
  });

  final String code;
  final String description;
  final OfferDiscount kind;

  /// The percent ([OfferDiscount.percent]) or the amount off.
  final int value;

  /// A percentage's cap; null for none.
  final int? maxDiscount;

  /// 0 for none.
  final int minimumFare;
  final DateTime validUntil;

  /// Empty: every ride type.
  final List<String> vehicleClasses;

  /// Only in some areas: the price says whether a pickup is in one.
  final bool limitedArea;

  /// How many more of the rider's trips it may take off.
  final int usesLeft;
  final bool newRidersOnly;
}

/// A discount without a code.
final class AutomaticOffer {
  const AutomaticOffer({required this.percent, this.maxAmount});

  final int percent;

  /// Null for no cap.
  final int? maxAmount;
}

/// Every [every]th completed trip is discounted: [tripsToGo] counts that trip
/// (1 means the next one).
final class LoyaltyOffer {
  const LoyaltyOffer({
    required this.every,
    required this.percent,
    required this.completedTrips,
    required this.tripsToGo,
    this.maxAmount,
  });

  final int every;
  final int percent;
  final int? maxAmount;
  final int completedTrips;
  final int tripsToGo;
}

/// What the home shows: the featured coupons the rider may use, the first-ride
/// discount (no trip yet) or the loyalty one.
final class RiderOffers {
  const RiderOffers({this.coupons = const [], this.firstRide, this.loyalty});

  final List<CouponOffer> coupons;
  final AutomaticOffer? firstRide;
  final LoyaltyOffer? loyalty;

  bool get isEmpty => coupons.isEmpty && firstRide == null && loyalty == null;
}

/// What a typed code is for the rider now.
enum CodeCheck { usable, notFound, ended, notStarted, expired, usedUp, alreadyUsed, newRidersOnly }

final class CodeCheckResult {
  const CodeCheckResult(this.check, [this.coupon]);

  final CodeCheck check;

  /// Set when it is usable.
  final CouponOffer? coupon;
}

/// A code as the rider typed it: trimmed, upper case. Codes are 3 to 40 letters,
/// digits, "-" or "_".
String? normalizeOfferCode(String typed) {
  final code = typed.trim().toUpperCase();

  return RegExp(r'^[A-Z0-9][A-Z0-9_-]{2,39}$').hasMatch(code) ? code : null;
}
