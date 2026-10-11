import '../../../../core/error/result.dart';
import '../entities/statement.dart';
import '../entities/voucher_credit.dart';
import '../entities/wallet_movement.dart';
import '../entities/wallet_overview.dart';

/// The rider's wallet: balance and fees owed, the latest movements, its history, and
/// the vouchers that add to it.
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

  /// Adds the voucher with [code] (whole, in capitals, without dashes) to the wallet.
  Future<Result<VoucherCredit>> redeemVoucher(String code);
}
