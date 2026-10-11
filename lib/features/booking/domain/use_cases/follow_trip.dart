import '../../../../core/error/result.dart';
import '../../../../core/location/geo_point.dart';
import '../entities/captain.dart';
import '../entities/ride.dart';
import '../entities/route_estimate.dart';
import '../repositories/captain_repository.dart';
import '../repositories/routes_repository.dart';

/// Who the captain of a trip is.
final class LoadCaptain {
  const LoadCaptain(this.captains);

  final CaptainRepository captains;

  Future<Result<Captain>> call(String tripId) => captains.captain(tripId);
}

/// Where the captain of a trip is now (null while not known).
final class LocateCaptain {
  const LocateCaptain(this.captains);

  final CaptainRepository captains;

  Future<Result<GeoPoint?>> call(String tripId) => captains.position(tripId);
}

/// The road still ahead of the captain, from where they are.
final class RouteAhead {
  const RouteAhead(this.routes);

  final RoutesRepository routes;

  Future<Result<RouteEstimate>> call(Ride ride, GeoPoint captain) =>
      routes.route([captain, ...pointsAhead(ride)]);
}

/// Where the captain still has to go: the pickup until the trip starts, then the
/// stops not reached yet and the destination.
List<GeoPoint> pointsAhead(Ride ride) => ride.status == RideStatus.onTrip
    ? [
        for (final stop in ride.stops)
          if (!stop.reached) stop.point,
        ride.dropoff,
      ]
    : [ride.pickup];
