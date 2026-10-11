import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/trip_payment.dart';
import '../repositories/trip_end_repository.dart';

/// How the trip was paid; null until the platform has settled it.
final class LoadPayment {
  const LoadPayment(this.trips);

  final TripEndRepository trips;

  Future<Result<TripPayment?>> call(String tripId) => trips.payment(tripId);
}

/// The rider's stars for the captain, and an optional word for the operator.
final class RateCaptain {
  const RateCaptain(this.trips);

  final TripEndRepository trips;

  static const int maxComment = 500;

  Future<Result<void>> call(String tripId, int stars, String comment) async {
    if (stars < 1 || stars > 5) {
      return const Err(InvalidInputFailure());
    }

    final words = comment.trim();

    return trips.rate(tripId, stars, words.length > maxComment ? words.substring(0, maxComment) : words);
  }
}

/// Why a tip cannot go.
enum TipProblem { tooSmall, tooBig, notEnoughMoney }

/// A tip from the rider's wallet, all of it for the captain.
final class TipCaptain {
  const TipCaptain(this.trips);

  final TripEndRepository trips;

  /// The platform's limits (wallet tip_min / tip_max).
  static const int minTip = 250;
  static const int maxTip = 25000;

  /// What stops [amount] from going with [balance] in the wallet, if anything.
  static TipProblem? problemOf(int amount, int balance) => switch (amount) {
        < minTip => TipProblem.tooSmall,
        > maxTip => TipProblem.tooBig,
        _ when amount > balance => TipProblem.notEnoughMoney,
        _ => null,
      };

  Future<Result<void>> call(String tripId, int amount, String key) => trips.tip(tripId, amount, key);
}
