import '../../../core/error/guard.dart';
import '../../../core/error/result.dart';
import '../../../core/network/json.dart';
import '../../../core/rider/rider_id.dart';
import '../../../core/security/session_storage.dart';
import '../domain/entities/offer.dart';
import '../domain/repositories/offers_repository.dart';
import 'offers_api.dart';

final class OffersRepositoryImpl implements OffersRepository {
  OffersRepositoryImpl(this._api);

  final OffersApi _api;

  @override
  Future<Result<RiderOffers>> offers() => guard(() async => riderOffersOf(await _api.offers(await riderIdOrSignIn())));

  @override
  Future<Result<CodeCheckResult>> check(String code) =>
      guard(() async => codeCheckOf(await _api.check(await riderIdOrSignIn(), code)));

  @override
  Future<String?> keptCode() async {
    try {
      return await SessionStorage.readKeptCoupon();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> keep(String code) => SessionStorage.saveKeptCoupon(code);

  /// Forgetting is best-effort: a code that stays kept is checked by the price again.
  @override
  Future<void> forget() async {
    try {
      await SessionStorage.deleteKeptCoupon();
    } catch (_) {}
  }
}

/// A ListRiderOffersResponse; fields at their defaults are left out.
RiderOffers riderOffersOf(JsonMap json) {
  final coupons = json['coupons'];
  final first = objectAt(json, 'firstRide');
  final loyalty = objectAt(json, 'loyalty');

  return RiderOffers(
    coupons: [
      if (coupons is List)
        for (final item in coupons)
          if (item is Map) couponOfferOf(decodeJsonObject(item)),
    ],
    firstRide: first == null
        ? null
        : AutomaticOffer(percent: amountAt(first, 'percent') ?? 0, maxAmount: _positive(first, 'maxAmount')),
    loyalty: loyalty == null
        ? null
        : LoyaltyOffer(
            every: _int(loyalty['every']),
            percent: amountAt(loyalty, 'percent') ?? 0,
            maxAmount: _positive(loyalty, 'maxAmount'),
            completedTrips: _int(loyalty['completedTrips']),
            tripsToGo: _int(loyalty['tripsToGo']),
          ),
  );
}

CouponOffer couponOfferOf(JsonMap json) {
  final until = DateTime.tryParse(json['validUntil'] is String ? json['validUntil'] as String : '');
  final classes = json['vehicleClasses'];
  final uses = _int(json['usesLeft']);

  return CouponOffer(
    code: requiredText(json, 'code'),
    description: json['description'] is String ? json['description'] as String : '',
    kind: json['discountType'] == 'DISCOUNT_TYPE_FIXED_AMOUNT' ? OfferDiscount.amount : OfferDiscount.percent,
    value: amountAt(json, 'discountValue') ?? 0,
    maxDiscount: _positive(json, 'maxDiscountAmount'),
    minimumFare: amountAt(json, 'minimumFareAmount') ?? 0,
    validUntil: until?.toLocal() ?? (throw const FormatException('no end in the offer')),
    vehicleClasses: [if (classes is List) for (final c in classes) if (c is String) c],
    limitedArea: json['limitedArea'] == true,
    usesLeft: uses < 1 ? 1 : uses,
    newRidersOnly: json['newRidersOnly'] == true,
  );
}

CodeCheckResult codeCheckOf(JsonMap json) {
  final coupon = objectAt(json, 'coupon');
  final check = switch (json['status']) {
    'COUPON_STATUS_APPLIED' => CodeCheck.usable,
    'COUPON_STATUS_ENDED' => CodeCheck.ended,
    'COUPON_STATUS_NOT_STARTED' => CodeCheck.notStarted,
    'COUPON_STATUS_EXPIRED' => CodeCheck.expired,
    'COUPON_STATUS_USED_UP' => CodeCheck.usedUp,
    'COUPON_STATUS_ALREADY_USED' => CodeCheck.alreadyUsed,
    'COUPON_STATUS_NEW_RIDERS_ONLY' => CodeCheck.newRidersOnly,
    _ => CodeCheck.notFound,
  };

  if (check == CodeCheck.usable && coupon != null) {
    return CodeCheckResult(check, couponOfferOf(coupon));
  }

  return CodeCheckResult(check == CodeCheck.usable ? CodeCheck.notFound : check);
}

int _int(Object? value) => value is num ? value.toInt() : int.tryParse(value is String ? value : '') ?? 0;

/// A positive amount at [key]; null when it is missing or 0.
int? _positive(JsonMap json, String key) {
  final value = amountAt(json, key);

  return value == null || value <= 0 ? null : value;
}
