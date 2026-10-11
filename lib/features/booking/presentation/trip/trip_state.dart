import 'dart:math' as math;

import '../../../../core/error/failure.dart';
import '../../../../core/location/geo_point.dart';
import '../../../../design/components/trip/route_markers.dart';
import '../../../../design/map/map_route.dart';
import '../../domain/entities/captain.dart';
import '../../domain/entities/ride.dart';
import '../../domain/entities/route_estimate.dart';

/// A ride with a captain, as the trip screen shows it.
final class TripState {
  const TripState({
    required this.ride,
    required this.map,
    this.captain,
    this.captainAt,
    this.ahead,
    this.cancelling = false,
    this.cancelledByRider = false,
    this.failure,
  });

  TripState.of(Ride ride) : this(ride: ride, map: tripMapOf(ride, null));

  final Ride ride;

  /// What the map draws: the points still ahead and the road to them.
  final MapRoute map;

  /// Null until it is loaded.
  final Captain? captain;
  final GeoPoint? captainAt;

  /// The road from the captain to where they go next, once worked out.
  final RouteEstimate? ahead;
  final bool cancelling;
  final bool cancelledByRider;

  /// Why the last cancel did not go through.
  final Failure? failure;

  TripStage get stage => ride.stage;

  /// The rider may cancel until the trip starts.
  bool get canCancel => stage == TripStage.coming || stage == TripStage.arrived;

  /// Whole minutes left on the road ahead (one at least), when known.
  int? get minutesAhead {
    final ahead = this.ahead;

    return ahead == null ? null : math.max(1, (ahead.duration.inSeconds / 60).ceil());
  }

  /// The same, with what changed. [failure] is replaced, not kept: a new state has
  /// none unless it is passed.
  TripState copyWith({
    Ride? ride,
    Captain? captain,
    GeoPoint? captainAt,
    bool? cancelling,
    bool? cancelledByRider,
    Failure? failure,
  }) =>
      TripState(
        ride: ride ?? this.ride,
        map: map,
        captain: captain ?? this.captain,
        captainAt: captainAt ?? this.captainAt,
        ahead: ahead,
        cancelling: cancelling ?? this.cancelling,
        cancelledByRider: cancelledByRider ?? this.cancelledByRider,
        failure: failure,
      );

  /// The same with a new road ahead (none when null), and the map drawn again for it.
  TripState withAhead(RouteEstimate? ahead) => TripState(
        ride: ride,
        map: tripMapOf(ride, ahead),
        captain: captain,
        captainAt: captainAt,
        ahead: ahead,
        cancelling: cancelling,
        cancelledByRider: cancelledByRider,
        failure: failure,
      );
}

/// The pickup until the trip starts; then the stops not reached and the destination.
/// The road is the one ahead of the captain.
MapRoute tripMapOf(Ride ride, RouteEstimate? ahead) => MapRoute(
      points: ride.status == RideStatus.onTrip
          ? [
              for (final stop in ride.stops)
                if (!stop.reached) (stop.point, RoutePointKind.stop),
              (ride.dropoff, RoutePointKind.destination),
            ]
          : [(ride.pickup, RoutePointKind.pickup)],
      path: ahead?.path ?? const [],
    );
