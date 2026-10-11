import '../../../../core/error/result.dart';
import '../entities/statement.dart';
import '../entities/wallet_movement.dart';
import '../entities/wallet_overview.dart';
import '../repositories/wallet_repository.dart';

/// The wallet screen's top: balance and what is owed, with the latest movements.
final class LoadWallet {
  const LoadWallet(this.wallet);

  final WalletRepository wallet;

  /// How many movements the wallet screen shows.
  static const int recentCount = 5;

  Future<Result<(WalletOverview, List<WalletMovement>)>> call() async {
    final (overview, recent) = (await wallet.overview(), await wallet.recent(recentCount));

    return switch ((overview, recent)) {
      (Ok(value: final o), Ok(value: final r)) => Ok((o, r)),
      (Err(:final failure), _) || (_, Err(:final failure)) => Err(failure),
    };
  }
}

/// The periods a statement covers, ending now.
enum StatementPeriod { days30, months3, year }

/// One page of the wallet's history over a period.
final class LoadStatement {
  const LoadStatement(this.wallet);

  final WalletRepository wallet;

  static Duration lengthOf(StatementPeriod period) => switch (period) {
        StatementPeriod.days30 => const Duration(days: 30),
        StatementPeriod.months3 => const Duration(days: 91),
        // The platform keeps a statement to 366 days.
        StatementPeriod.year => const Duration(days: 365),
      };

  Future<Result<StatementPage>> call({
    required StatementPeriod period,
    required DateTime now,
    MovementFilter filter = MovementFilter.all,
    String? page,
  }) =>
      wallet.statement(from: now.subtract(lengthOf(period)), to: now, filter: filter, page: page);
}
