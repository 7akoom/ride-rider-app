import 'payment_method.dart';
import 'ride.dart';

enum ScheduledStatus { scheduled, dispatched, cancelled, failed }

/// A ride booked ahead. Its price is set when it is requested, at the time.
final class ScheduledRide {
  const ScheduledRide({
    required this.id,
    required this.status,
    required this.at,
    required this.vehicleClass,
    required this.payment,
    this.pickupAddress = '',
    this.dropoffAddress = '',
    this.stops = const [],
  });

  final String id;
  final ScheduledStatus status;

  /// When to be picked up.
  final DateTime at;
  final String vehicleClass;
  final PaymentMethod payment;
  final String pickupAddress;
  final String dropoffAddress;
  final List<RideStop> stops;
}
