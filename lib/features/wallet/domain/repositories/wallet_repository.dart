import '../../../../core/error/result.dart';
import '../entities/statement.dart';
import '../entities/wallet_movement.dart';
import '../entities/wallet_overview.dart';

/// The rider's wallet: balance and fees owed, the latest movements, and its history.
abstract interface class WalletRepository {
  Future<Result<WalletOverview>> overview();

  /// The latest [limit] movements.
  Future<Result<List<WalletMovement>>> recent(int limit);

  /// Movements from [from] to [to] that [filter] keeps, a page from [page] on.
  Future<Result<StatementPage>> statement({
    required DateTime from,
    required DateTime to,
    MovementFilter filter = MovementFilter.all,
    String? page,
  });
}
