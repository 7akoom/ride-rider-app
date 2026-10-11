import '../../../core/network/json.dart';
import '../domain/entities/fare_quote.dart';

/// Reads the answer of /v1/fare-quotes. Fields the gateway leaves out are their zero
/// value (false, 0, "").
abstract final class FareQuoteJson {
  static FareQuotes quotesOf(JsonMap json) {
    final items = json['quotes'];

    return FareQuotes([
      if (items is List)
        for (final item in items)
          if (item is Map) quoteOf(decodeJsonObject(item)),
    ]);
  }

  static FareQuote quoteOf(JsonMap json) {
    final fare = objectAt(json, 'fare') ?? const <String, dynamic>{};
    final total = requiredAmount(fare, 'total');
    final discount = amountAt(fare, 'discountAmount') ?? 0;
    final eta = json['pickupEtaMinutes'];

    return FareQuote(
      id: requiredText(json, 'quoteId'),
      vehicleClass: requiredText(json, 'vehicleClass'),
      total: total,
      beforeDiscount: discount > 0 ? total + discount : null,
      expiresAt: DateTime.parse(requiredText(json, 'expiresAt')),
      driversAvailable: json['driversAvailable'] == true,
      pickupEtaMinutes: eta is num ? eta.round() : 0,
      surging: (amountAt(fare, 'surgeAmount') ?? 0) > 0,
      coupon: couponOf(fare['couponStatus']),
      discount: discount > 0 ? discountOf(fare['appliedDiscountLabel']) : DiscountKind.none,
    );
  }

  /// The server names the discount in English for its staff ("First ride discount",
  /// "Loyalty discount", "Coupon: CODE"); the app shows its own words for each.
  static DiscountKind discountOf(Object? label) => switch (label) {
        'First ride discount' => DiscountKind.firstRide,
        'Loyalty discount' => DiscountKind.loyalty,
        String text when text.startsWith('Coupon:') => DiscountKind.coupon,
        _ => DiscountKind.other,
      };

  static CouponResult couponOf(Object? status) => switch (status) {
        'COUPON_STATUS_APPLIED' => CouponResult.applied,
        'COUPON_STATUS_NOT_FOUND' => CouponResult.notFound,
        'COUPON_STATUS_ENDED' => CouponResult.ended,
        'COUPON_STATUS_NOT_STARTED' => CouponResult.notStarted,
        'COUPON_STATUS_EXPIRED' => CouponResult.expired,
        'COUPON_STATUS_USED_UP' => CouponResult.usedUp,
        'COUPON_STATUS_ALREADY_USED' => CouponResult.alreadyUsed,
        'COUPON_STATUS_NOT_IN_AREA' => CouponResult.notInArea,
        'COUPON_STATUS_NOT_FOR_CLASS' => CouponResult.notForClass,
        'COUPON_STATUS_NEW_RIDERS_ONLY' => CouponResult.newRidersOnly,
        'COUPON_STATUS_BELOW_MINIMUM' => CouponResult.belowMinimum,
        'COUPON_STATUS_BETTER_DISCOUNT' => CouponResult.betterDiscount,
        _ => CouponResult.none,
      };
}
