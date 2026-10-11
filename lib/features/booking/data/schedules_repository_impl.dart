import '../../../core/error/guard.dart';
import '../../../core/error/result.dart';
import '../domain/entities/passenger.dart';
import '../domain/entities/payment_method.dart';
import '../domain/entities/scheduled_ride.dart';
import '../domain/entities/trip_draft.dart';
import '../domain/repositories/schedules_repository.dart';
import '../../../core/rider/rider_id.dart';
import 'rides_api.dart';
import 'scheduled_ride_json.dart';
import 'trip_body.dart';

final class SchedulesRepositoryImpl implements SchedulesRepository {
  SchedulesRepositoryImpl(this._api);

  final RidesApi _api;

  @override
  Future<Result<ScheduledRide>> book({
    required TripDraft draft,
    required String vehicleClass,
    required PaymentMethod payment,
    required DateTime at,
    required String key,
    Passenger? passenger,
  }) =>
      guard(() async {
        final json = await _api.scheduleTrip({
          'riderId': await riderIdOrSignIn(),
          ...TripBody.of(draft, passenger: passenger),
          'vehicleClass': vehicleClass,
          'paymentMethod': payment.name,
          'scheduledAt': at.toUtc().toIso8601String(),
          'idempotencyKey': key,
        });

        return ScheduledRideJson.fromAnswer(json);
      });

  @override
  Future<Result<ScheduledRide>> cancel(String id) => guard(() async {
        final json = await _api.cancelScheduled(id, await riderIdOrSignIn());

        return ScheduledRideJson.fromAnswer(json);
      });
}
