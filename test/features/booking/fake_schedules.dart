import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/features/booking/domain/entities/passenger.dart';
import 'package:rider_app/features/booking/domain/entities/payment_method.dart';
import 'package:rider_app/features/booking/domain/entities/scheduled_ride.dart';
import 'package:rider_app/features/booking/domain/entities/trip_draft.dart';
import 'package:rider_app/features/booking/domain/repositories/schedules_repository.dart';

ScheduledRide bookingOf({String id = 'b1', DateTime? at}) => ScheduledRide(
      id: id,
      status: ScheduledStatus.scheduled,
      at: at ?? DateTime(2026, 10, 12, 8, 30),
      vehicleClass: 'economy',
      payment: PaymentMethod.cash,
      pickupAddress: 'Gulan Street',
      dropoffAddress: 'Family Mall',
    );

class FakeSchedules implements SchedulesRepository {
  FakeSchedules({this.bookFailure});

  Failure? bookFailure;
  final List<(DateTime, String)> booked = [];
  final List<String> cancelled = [];

  @override
  Future<Result<ScheduledRide>> book({
    required TripDraft draft,
    required String vehicleClass,
    required PaymentMethod payment,
    required DateTime at,
    required String key,
    Passenger? passenger,
  }) async {
    booked.add((at, key));
    final f = bookFailure;

    return f == null ? Ok(bookingOf(at: at)) : Err(f);
  }

  @override
  Future<Result<ScheduledRide>> cancel(String id) async {
    cancelled.add(id);

    return Ok(bookingOf(id: id));
  }
}
