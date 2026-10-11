/// What a redeemed voucher did: the amount it added, and the wallet's balance after
/// it (fees still owed are paid from it first).
final class VoucherCredit {
  const VoucherCredit({required this.amount, required this.balance, this.alreadyRedeemed = false});

  final int amount;
  final int balance;

  /// The rider had redeemed this voucher before: nothing was added this time, and
  /// [amount] is what it added then.
  final bool alreadyRedeemed;
}
