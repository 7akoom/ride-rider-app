import '../../../../core/error/result.dart';
import '../entities/trip_payment.dart';

/// After a trip: how it was paid, the rider's rating of the captain, and a tip.
abstract interface class TripEndRepository {
  /// Null while the platform has not settled the trip yet (a few seconds).
  Future<Result<TripPayment?>> payment(String tripId);

  /// Rating twice is not a failure: the first one stands.
  Future<Result<void>> rate(String tripId, int stars, String comment);

  /// The same [key] again is the same tip, never a second one.
  Future<Result<void>> tip(String tripId, int amount, String key);
}
