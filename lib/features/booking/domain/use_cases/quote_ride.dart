import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/fare_quote.dart';
import '../entities/trip_draft.dart';
import '../repositories/rides_repository.dart';

/// The prices of every ride type for the trip, with the rider's coupon when there is
/// one. Codes are compared without case or spaces around them.
final class QuoteRide {
  const QuoteRide(this.rides);

  final RidesRepository rides;

  Future<Result<FareQuotes>> call(TripDraft draft, {String? couponCode}) async {
    if (!draft.isComplete) {
      return const Err(InvalidInputFailure());
    }

    return rides.quote(draft, couponCode: normalizeCoupon(couponCode));
  }
}

/// The code as the backend expects it, or null for nothing typed.
String? normalizeCoupon(String? code) {
  final trimmed = code?.trim().toUpperCase() ?? '';

  return trimmed.isEmpty ? null : trimmed;
}

/// Pricing refused the trip's points: the pickup is outside every service zone (the
/// app sends nothing else it could reject).
bool isOutsideServiceArea(Failure failure) => failure is InvalidInputFailure;
