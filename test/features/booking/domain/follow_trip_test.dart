import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/location/geo_point.dart';
import 'package:rider_app/features/booking/domain/entities/ride.dart';
import 'package:rider_app/features/booking/domain/use_cases/follow_trip.dart';

import '../fakes.dart';

Ride _withStops(RideStatus status) {
  final ride = rideOf(status: status);

  return Ride(
    id: ride.id,
    status: status,
    pickup: ride.pickup,
    dropoff: ride.dropoff,
    vehicleClass: ride.vehicleClass,
    payment: ride.payment,
    stops: const [
      RideStop(point: GeoPoint(36.2, 44.0), reached: true),
      RideStop(point: GeoPoint(36.21, 44.0)),
    ],
  );
}

void main() {
  test('before the trip starts the captain heads for the pickup', () {
    final ride = _withStops(RideStatus.accepted);

    expect(pointsAhead(ride), [ride.pickup]);
  });

  test('on the trip: the stops not reached, then the destination', () {
    final ride = _withStops(RideStatus.onTrip);

    expect(pointsAhead(ride), [const GeoPoint(36.21, 44.0), ride.dropoff]);
  });

  test('the stage follows the status and the arrival', () {
    expect(rideOf().stage, TripStage.searching);
    expect(rideOf(status: RideStatus.accepted).stage, TripStage.coming);
    expect(rideOf(status: RideStatus.accepted, arrivedAt: DateTime(2026)).stage, TripStage.arrived);
    expect(rideOf(status: RideStatus.onTrip).stage, TripStage.onTrip);
  });
}
