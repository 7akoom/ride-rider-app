import '../../../../core/error/result.dart';
import '../entities/passenger.dart';
import '../entities/payment_method.dart';
import '../entities/scheduled_ride.dart';
import '../entities/trip_draft.dart';

/// Rides booked ahead.
abstract interface class SchedulesRepository {
  /// Books the trip for [at]. The same [key] again is the same booking (a retry
  /// never books twice).
  Future<Result<ScheduledRide>> book({
    required TripDraft draft,
    required String vehicleClass,
    required PaymentMethod payment,
    required DateTime at,
    required String key,
    Passenger? passenger,
  });

  /// Free while no captain is being looked for yet.
  Future<Result<ScheduledRide>> cancel(String id);
}
