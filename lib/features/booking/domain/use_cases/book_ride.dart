import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/passenger.dart';
import '../entities/payment_method.dart';
import '../entities/scheduled_ride.dart';
import '../entities/trip_draft.dart';
import '../repositories/schedules_repository.dart';
import 'schedule_window.dart';

/// Why a booking was refused, when the rider can do something about it.
enum BookingProblem {
  /// The time is no longer far enough ahead (or too far).
  timeGone,

  /// As many upcoming bookings as allowed already.
  tooMany,
}

/// Books the drafted trip ahead, at a time the window allows when it is sent.
final class BookRide {
  const BookRide(this.schedules, {this.window = const ScheduleWindow(), DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final SchedulesRepository schedules;
  final ScheduleWindow window;
  final DateTime Function() _clock;

  Future<Result<ScheduledRide>> call({
    required TripDraft draft,
    required String vehicleClass,
    required PaymentMethod payment,
    required DateTime at,
    required String key,
    Passenger? passenger,
  }) async {
    if (!draft.isComplete || !window.allows(at, _clock())) {
      return const Err(InvalidInputFailure());
    }

    return schedules.book(
      draft: draft,
      vehicleClass: vehicleClass,
      payment: payment,
      at: at,
      key: key,
      passenger: passenger,
    );
  }
}

/// The trip-service refuses a time out of range (and a pickup outside the zones)
/// with InvalidArgument, and too many upcoming bookings with FailedPrecondition.
BookingProblem? bookingProblemOf(Failure failure) => switch (failure) {
      InvalidInputFailure() => BookingProblem.timeGone,
      PreconditionFailure() => BookingProblem.tooMany,
      _ => null,
    };

/// The rider calls the booking off.
final class CancelBooking {
  const CancelBooking(this.schedules);

  final SchedulesRepository schedules;

  Future<Result<ScheduledRide>> call(String id) => schedules.cancel(id);
}
