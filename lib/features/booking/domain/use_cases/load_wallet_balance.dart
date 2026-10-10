import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../repositories/rides_repository.dart';

/// The rider's wallet balance. A rider who never used the wallet has none yet: zero.
final class LoadWalletBalance {
  const LoadWalletBalance(this.rides);

  final RidesRepository rides;

  Future<Result<int>> call() async {
    final result = await rides.walletBalance();

    return switch (result) {
      Err(failure: NotFoundFailure()) => const Ok(0),
      _ => result,
    };
  }
}
