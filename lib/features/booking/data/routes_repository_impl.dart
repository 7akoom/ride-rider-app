import '../../../core/error/guard.dart';
import '../../../core/error/result.dart';
import '../../../core/location/geo_point.dart';
import '../../../core/location/polyline.dart';
import '../domain/entities/route_estimate.dart';
import '../domain/repositories/routes_repository.dart';
import 'booking_api.dart';

final class RoutesRepositoryImpl implements RoutesRepository {
  RoutesRepositoryImpl(this._api);

  final BookingApi _api;

  @override
  Future<Result<RouteEstimate>> route(List<GeoPoint> points) => guard(() async {
        if (points.length < 2) {
          throw ArgumentError.value(points.length, 'points', 'a route needs two ends');
        }

        final json = await _api.route(points);
        final meters = json['distanceMeters'];
        final seconds = json['durationSeconds'];
        final polyline = json['polyline'];

        return RouteEstimate(
          distanceMeters: meters is num ? meters.toDouble() : 0,
          duration: Duration(seconds: seconds is num ? seconds.round() : 0),
          path: polyline is String ? decodePolyline(polyline) : const <GeoPoint>[],
        );
      });
}
