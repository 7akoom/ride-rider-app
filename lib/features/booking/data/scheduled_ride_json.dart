import '../../../core/location/geo_point.dart';
import '../../../core/network/json.dart';
import '../domain/entities/payment_method.dart';
import '../domain/entities/ride.dart';
import '../domain/entities/scheduled_ride.dart';

/// Reads a booking (`{"scheduledTrip": {...}}` answers).
abstract final class ScheduledRideJson {
  static ScheduledRide fromAnswer(JsonMap answer) {
    final json = objectAt(answer, 'scheduledTrip') ?? const <String, dynamic>{};
    final stops = json['stops'];

    return ScheduledRide(
      id: requiredText(json, 'id'),
      status: switch (json['status']) {
        'dispatched' => ScheduledStatus.dispatched,
        'cancelled' => ScheduledStatus.cancelled,
        'failed' => ScheduledStatus.failed,
        _ => ScheduledStatus.scheduled,
      },
      at: DateTime.parse(requiredText(json, 'scheduledAt')),
      vehicleClass: _text(json['vehicleClass']),
      payment: json['paymentMethod'] == 'wallet' ? PaymentMethod.wallet : PaymentMethod.cash,
      pickupAddress: _text(json['pickupAddress']),
      dropoffAddress: _text(json['dropoffAddress']),
      stops: [
        if (stops is List)
          for (final stop in stops)
            if (stop is Map)
              RideStop(point: GeoPoint.fromJson(stop['coordinates']), address: _text(stop['address'])),
      ],
    );
  }

  static String _text(Object? value) => value is String ? value.trim() : '';
}
