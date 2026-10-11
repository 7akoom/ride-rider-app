import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/features/booking/domain/entities/payment_method.dart';
import 'package:rider_app/features/booking/domain/entities/trip_draft.dart';
import 'package:rider_app/features/booking/domain/use_cases/book_ride.dart';
import 'package:rider_app/features/booking/domain/use_cases/schedule_window.dart';

import '../fakes.dart';

final _draft = TripDraft(pickup: spotNamed('Gulan'), destination: spotNamed('Mall'));
const _window = ScheduleWindow();

void main() {
  test('the first time is half an hour (and a little) ahead, on five minutes', () {
    expect(_window.earliest(DateTime(2026, 10, 11, 9, 0)), DateTime(2026, 10, 11, 9, 35));
    expect(_window.earliest(DateTime(2026, 10, 11, 9, 3, 10)), DateTime(2026, 10, 11, 9, 40));
    expect(_window.earliest(DateTime(2026, 10, 11, 23, 50)), DateTime(2026, 10, 12, 0, 25));
  });

  test('a late evening offers tomorrow first, and seven days at most', () {
    final now = DateTime(2026, 10, 11, 23, 40);
    final days = _window.days(now);

    expect(days.first, DateTime(2026, 10, 12));
    expect(days.last, DateTime(2026, 10, 18));
    expect(_window.timesOn(days.last, now).last, DateTime(2026, 10, 18, 23, 40));
  });

  test('times step by five minutes inside the window', () {
    final now = DateTime(2026, 10, 11, 9, 0);
    final today = _window.timesOn(DateTime(2026, 10, 11), now);

    expect(today.first, DateTime(2026, 10, 11, 9, 35));
    expect(today[1], DateTime(2026, 10, 11, 9, 40));
    expect(today.last, DateTime(2026, 10, 11, 23, 55));
  });

  test('a time no longer allowed is not sent', () async {
    final schedules = FakeSchedules();
    final now = DateTime(2026, 10, 11, 9, 0);

    final result = await BookRide(schedules, clock: () => now).call(
      draft: _draft,
      vehicleClass: 'economy',
      payment: PaymentMethod.cash,
      at: now.add(const Duration(minutes: 10)),
      key: 'k',
    );

    expect(schedules.booked, isEmpty);
    expect(bookingProblemOf((result as Err).failure), BookingProblem.timeGone);
  });

  test('an allowed time is booked with its key', () async {
    final schedules = FakeSchedules();
    final now = DateTime(2026, 10, 11, 9, 0);
    final at = DateTime(2026, 10, 11, 18, 0);

    final result = await BookRide(schedules, clock: () => now).call(
      draft: _draft,
      vehicleClass: 'economy',
      payment: PaymentMethod.cash,
      at: at,
      key: 'k1',
    );

    expect(result, isA<Ok>());
    expect(schedules.booked.single, (at, 'k1'));
    expect(bookingProblemOf(const PreconditionFailure()), BookingProblem.tooMany);
  });
}
