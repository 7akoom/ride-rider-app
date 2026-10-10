import 'dart:math' as math;

import 'geo_point.dart';

const double _earthRadiusMeters = 6371000;

/// The straight-line distance between two points on Earth, in meters (haversine). Good
/// for "how far is it", not for a fare: fares come from the road route.
double metersBetween(GeoPoint a, GeoPoint b) {
  double rad(double degrees) => degrees * math.pi / 180;

  final dLat = rad(b.latitude - a.latitude);
  final dLng = rad(b.longitude - a.longitude);
  final h = math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(a.latitude)) * math.cos(rad(b.latitude)) * math.pow(math.sin(dLng / 2), 2);

  return 2 * _earthRadiusMeters * math.asin(math.sqrt(h));
}
