import '../../../../core/location/geo_point.dart';
import 'payment_method.dart';

enum RideStatus { searching, accepted, onTrip, completed, cancelled }

/// A stop on the way, as it was requested.
final class RideStop {
  const RideStop({required this.point, this.address = ''});

  final GeoPoint point;
  final String address;
}

/// A requested trip, as far as booking follows it: until a captain accepts it, or it
/// ends without one.
final class Ride {
  const Ride({
    required this.id,
    required this.status,
    required this.pickup,
    required this.dropoff,
    required this.vehicleClass,
    required this.payment,
    this.pickupAddress = '',
    this.dropoffAddress = '',
    this.stops = const [],
    this.fare,
    this.requestedAt,
    this.cancelledBySystem = false,
    this.cancellationReason = '',
  });

  final String id;
  final RideStatus status;
  final GeoPoint pickup;
  final GeoPoint dropoff;
  final String pickupAddress;
  final String dropoffAddress;
  final List<RideStop> stops;
  final String vehicleClass;
  final PaymentMethod payment;

  /// The quoted price in whole currency units; null when it is priced at the end.
  final int? fare;
  final DateTime? requestedAt;
  final bool cancelledBySystem;
  final String cancellationReason;

  /// The search for a captain ran out: the platform cancelled it for want of one.
  bool get noCaptainFound =>
      status == RideStatus.cancelled &&
      cancelledBySystem &&
      cancellationReason.toLowerCase().contains('no driver');

  /// A captain is on the way or the trip is under way.
  bool get hasCaptain => status == RideStatus.accepted || status == RideStatus.onTrip;
}
