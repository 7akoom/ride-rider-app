import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/route_estimate.dart';
import '../entities/trip_draft.dart';
import '../repositories/routes_repository.dart';

/// The road for the trip as drafted. A draft without both ends has no route yet.
final class EstimateRoute {
  const EstimateRoute(this.routes);

  final RoutesRepository routes;

  Future<Result<RouteEstimate>> call(TripDraft draft) async {
    if (!draft.isComplete) {
      return const Err(InvalidInputFailure());
    }

    return routes.route(draft.points);
  }
}

/// No road between the points (404), or a point too far from any road (400): the
/// rider should move a point, not try again.
bool isNoRoad(Failure failure) =>
    failure is NotFoundFailure || failure is InvalidInputFailure;
