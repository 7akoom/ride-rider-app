import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/voucher_code.dart';
import '../entities/voucher_credit.dart';
import '../repositories/wallet_repository.dart';

/// Adds a voucher's amount to the rider's wallet. A code that is not whole is refused
/// here, so it never reaches the server (where wrong codes are counted).
final class RedeemVoucher {
  const RedeemVoucher(this.wallet);

  final WalletRepository wallet;

  Future<Result<VoucherCredit>> call(String typed) async {
    final code = VoucherCode.clean(typed);

    if (code == null || code.length != VoucherCode.length) {
      return const Err(InvalidInputFailure());
    }

    return wallet.redeemVoucher(code);
  }
}
