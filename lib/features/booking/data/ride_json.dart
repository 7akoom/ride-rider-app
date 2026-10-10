import '../../../core/location/geo_point.dart';
import '../../../core/network/json.dart';
import '../domain/entities/payment_method.dart';
import '../domain/entities/ride.dart';

/// Reads a trip of the gateway (`{"trip": {...}}` answers) as a ride.
abstract final class RideJson {
  static Ride fromAnswer(JsonMap answer) =>
      fromTrip(objectAt(answer, 'trip') ?? const <String, dynamic>{});

  static Ride fromTrip(JsonMap json) {
    final stops = json['stops'];

    return Ride(
      id: requiredText(json, 'id'),
      status: statusOf(json['status']),
      pickup: GeoPoint.fromJson(json['pickup']),
      dropoff: GeoPoint.fromJson(json['dropoff']),
      pickupAddress: _text(json['pickupAddress']),
      dropoffAddress: _text(json['dropoffAddress']),
      stops: [
        if (stops is List)
          for (final stop in stops)
            if (stop is Map)
              RideStop(
                point: GeoPoint.fromJson(stop['coordinates']),
                address: _text(stop['address']),
              ),
      ],
      vehicleClass: _text(json['vehicleClass']),
      payment: json['paymentMethod'] == 'wallet' ? PaymentMethod.wallet : PaymentMethod.cash,
      fare: amountAt(json, 'quotedFare'),
      requestedAt: DateTime.tryParse(_text(json['requestedAt'])),
      cancelledBySystem: json['cancelledBy'] == 'system',
      cancellationReason: _text(json['cancellationReason']),
    );
  }

  static RideStatus statusOf(Object? status) => switch (status) {
        'TRIP_STATUS_ACCEPTED' => RideStatus.accepted,
        'TRIP_STATUS_IN_PROGRESS' => RideStatus.onTrip,
        'TRIP_STATUS_COMPLETED' => RideStatus.completed,
        'TRIP_STATUS_CANCELLED' => RideStatus.cancelled,
        _ => RideStatus.searching,
      };

  static String _text(Object? value) => value is String ? value.trim() : '';
}
