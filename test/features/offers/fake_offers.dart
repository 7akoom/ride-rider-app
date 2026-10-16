import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/core/location/geo_point.dart';
import 'package:rider_app/features/home/domain/recent_destination.dart';
import 'package:rider_app/features/offers/domain/entities/offer.dart';
import 'package:rider_app/features/offers/domain/repositories/offers_repository.dart';

/// A coupon for tests: 30% up to 3,000, for a week.
CouponOffer couponOf(
  String code, {
  String description = '',
  OfferDiscount kind = OfferDiscount.percent,
  int value = 30,
  int? maxDiscount = 3000,
  int usesLeft = 1,
  bool newRidersOnly = false,
}) =>
    CouponOffer(
      code: code,
      description: description,
      kind: kind,
      value: value,
      maxDiscount: maxDiscount,
      validUntil: DateTime.now().add(const Duration(days: 7)),
      usesLeft: usesLeft,
      newRidersOnly: newRidersOnly,
    );

class FakeOffers implements OffersRepository {
  FakeOffers({
    this.result = const Ok(RiderOffers()),
    Map<String, CodeCheckResult>? checks,
    this.kept,
  }) : checks = checks ?? {};

  Result<RiderOffers> result;

  /// What each code checks as; any other is not found.
  Map<String, CodeCheckResult> checks;

  /// The code kept for the next ride.
  String? kept;
  final List<String> checked = [];
  int forgotten = 0;

  @override
  Future<Result<RiderOffers>> offers() async => result;

  @override
  Future<Result<CodeCheckResult>> check(String code) async {
    checked.add(code);

    return Ok(checks[code] ?? const CodeCheckResult(CodeCheck.notFound));
  }

  @override
  Future<String?> keptCode() async => kept;

  @override
  Future<void> keep(String code) async => kept = code;

  @override
  Future<void> forget() async {
    forgotten++;
    kept = null;
  }
}

class FakeRecentDestinations implements RecentDestinationsRepository {
  FakeRecentDestinations([this.result = const Ok(<RecentDestination>[])]);

  Result<List<RecentDestination>> result;

  @override
  Future<Result<List<RecentDestination>>> recent({int limit = 1}) async => result;
}

const RecentDestination familyMall =
    RecentDestination(point: GeoPoint(36.23, 43.98), address: 'Family Mall');
