import '../../../../core/error/failure.dart';
import '../../domain/entities/ride.dart';

enum SearchPhase {
  /// Waiting for a captain to take the ride.
  waiting,
  cancelling,

  /// The search ran out without a captain (16).
  noCaptain,
  retrying,

  /// A captain took it: the trip screen follows.
  captainFound,

  /// It ended without a captain: cancelled by the rider, or by staff.
  ended,
}

final class SearchingState {
  const SearchingState({
    required this.ride,
    required this.phase,
    this.failure,
    this.cancelledByRider = false,
  });

  final Ride ride;
  final SearchPhase phase;

  /// Why the last cancel or retry did not go through.
  final Failure? failure;
  final bool cancelledByRider;

  /// The phase a ride's own state puts the screen in.
  static SearchPhase phaseOf(Ride ride) => switch (ride.status) {
        _ when ride.hasCaptain || ride.status == RideStatus.completed => SearchPhase.captainFound,
        _ when ride.noCaptainFound => SearchPhase.noCaptain,
        RideStatus.cancelled => SearchPhase.ended,
        _ => SearchPhase.waiting,
      };
}
