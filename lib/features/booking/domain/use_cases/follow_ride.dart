import '../../../../core/error/result.dart';
import '../entities/cancellation.dart';
import '../entities/ride.dart';
import '../repositories/rides_repository.dart';

/// The state of a requested ride, read again while it waits for a captain.
final class LoadRide {
  const LoadRide(this.rides);

  final RidesRepository rides;

  Future<Result<Ride>> call(String id) => rides.ride(id);
}

/// The rider's ride that has not ended (after the app was closed), or null.
final class FindActiveRide {
  const FindActiveRide(this.rides);

  final RidesRepository rides;

  Future<Result<Ride?>> call() => rides.activeRide();
}

/// The rider gives up the ride: while no captain has it, or later saying [why].
final class CancelRide {
  const CancelRide(this.rides);

  final RidesRepository rides;

  Future<Result<Ride>> call(String id, {Cancellation? why}) => rides.cancel(id, why: why);
}
