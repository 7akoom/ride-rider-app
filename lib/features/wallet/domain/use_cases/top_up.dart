import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/top_up.dart';
import '../repositories/wallet_repository.dart';

/// What a top-up may be here, and whether the wallet offers it at all.
final class LoadTopUpOptions {
  const LoadTopUpOptions(this.wallet);

  final WalletRepository wallet;

  Future<Result<TopUpOptions>> call() => wallet.topUpOptions();
}

/// Opens a ZainCash payment to top up the wallet. An amount outside the limits, or a
/// deployment without ZainCash, is refused here, before the server is asked.
final class StartTopUp {
  const StartTopUp(this.wallet);

  final WalletRepository wallet;

  Future<Result<TopUpStart>> call({
    required int amount,
    required TopUpOptions options,
    required String language,
  }) async {
    if (!options.available) {
      return const Err(PreconditionFailure());
    }

    if (options.problemOf(amount) != null) {
      return const Err(InvalidInputFailure());
    }

    return wallet.startTopUp(amount: amount, language: language);
  }
}

/// How a top-up stands, as the server (and through it the provider) says.
final class CheckTopUp {
  const CheckTopUp(this.wallet);

  final WalletRepository wallet;

  Future<Result<TopUpStatus>> call(String id) => wallet.topUpStatus(id);
}
