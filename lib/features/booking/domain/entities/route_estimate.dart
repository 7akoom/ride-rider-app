import '../../../../core/location/geo_point.dart';

/// The road between the trip's points: how long, how far, and the line to draw.
final class RouteEstimate {
  const RouteEstimate({
    required this.distanceMeters,
    required this.duration,
    required this.path,
  });

  final double distanceMeters;
  final Duration duration;
  final List<GeoPoint> path;
}
