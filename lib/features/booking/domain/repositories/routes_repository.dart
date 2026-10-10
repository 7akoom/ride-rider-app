import '../../../../core/error/result.dart';
import '../../../../core/location/geo_point.dart';
import '../entities/route_estimate.dart';

/// Roads between points.
abstract interface class RoutesRepository {
  /// The best road through [points] in order (at least two: from, the stops, to).
  Future<Result<RouteEstimate>> route(List<GeoPoint> points);
}
