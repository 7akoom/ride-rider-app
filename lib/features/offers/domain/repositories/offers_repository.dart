import '../../../../core/error/result.dart';
import '../entities/offer.dart';

/// The rider's offers (pricing-service), and the code kept for their next ride.
abstract interface class OffersRepository {
  Future<Result<RiderOffers>> offers();

  /// Whether the rider may use [code] now; it needs no trip (the area, the ride type
  /// and the minimum fare are checked with the price).
  Future<Result<CodeCheckResult>> check(String code);

  /// The code the rider chose for their next ride; null for none.
  Future<String?> keptCode();

  Future<void> keep(String code);

  Future<void> forget();
}
