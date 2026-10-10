import '../../core/location/geo_point.dart';
import '../components/trip/route_markers.dart';

/// A trip drawn on the map: the road and its points, each with its marker kind.
final class MapRoute {
  const MapRoute({required this.points, this.path = const []});

  /// Pickup, stops and destination, in order.
  final List<(GeoPoint, RoutePointKind)> points;

  /// The road between them; empty while it is not known (the points still show).
  final List<GeoPoint> path;

  /// Everything the camera has to show.
  List<GeoPoint> get extent => [for (final (point, _) in points) point, ...path];
}
