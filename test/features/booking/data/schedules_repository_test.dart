import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/features/booking/data/schedules_repository_impl.dart';
import 'package:rider_app/features/booking/domain/entities/passenger.dart';
import 'package:rider_app/features/booking/domain/entities/payment_method.dart';
import 'package:rider_app/features/booking/domain/entities/scheduled_ride.dart';
import 'package:rider_app/features/booking/domain/entities/trip_draft.dart';

import '../fakes.dart';
import 'fake_rides_api.dart';

final _draft = TripDraft(pickup: spotNamed('Gulan'), destination: spotNamed('Family Mall'));

const _answer = {
  'scheduledTrip': {
    'id': 's1',
    'status': 'scheduled',
    'scheduledAt': '2026-10-12T05:30:00Z',
    'vehicleClass': 'comfort',
    'paymentMethod': 'wallet',
    'pickupAddress': 'Gulan',
    'dropoffAddress': 'Family Mall',
  },
};

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({'rider_id': 'r1'}));

  test('a booking carries the time in UTC, its key, the passenger and the trip', () async {
    final api = FakeRidesApi()..bookingAnswer = _answer;

    final result = await SchedulesRepositoryImpl(api).book(
      draft: _draft,
      vehicleClass: 'comfort',
      payment: PaymentMethod.wallet,
      at: DateTime.utc(2026, 10, 12, 5, 30),
      key: 'key-1',
      passenger: const Passenger(name: 'Rania', phone: '+9647504489210'),
    );
    final booking = (result as Ok<ScheduledRide>).value;

    expect(api.sent?['scheduledAt'], '2026-10-12T05:30:00.000Z');
    expect(api.sent?['idempotencyKey'], 'key-1');
    expect(api.sent?['riderId'], 'r1');
    expect(api.sent?['passengerName'], 'Rania');
    expect(api.sent?['dropoffAddress'], 'Family Mall');
    expect(booking.id, 's1');
    expect(booking.at, DateTime.utc(2026, 10, 12, 5, 30));
    expect(booking.payment, PaymentMethod.wallet);
  });

  test('cancelling names the booking', () async {
    final api = FakeRidesApi()..bookingAnswer = {
      'scheduledTrip': {..._answer['scheduledTrip']!, 'status': 'cancelled'},
    };

    final result = await SchedulesRepositoryImpl(api).cancel('s1');

    expect(api.cancelledBooking, 's1');
    expect((result as Ok<ScheduledRide>).value.status, ScheduledStatus.cancelled);
  });
}
