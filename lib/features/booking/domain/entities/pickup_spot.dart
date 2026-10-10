import '../../../../core/location/geo_point.dart';

/// Where the rider will be picked up: a point, and what is there when the map knows.
final class PickupSpot {
  const PickupSpot({required this.point, this.address});

  final GeoPoint point;

  /// A street or a place name; null when the map has nothing for the point.
  final String? address;
}
