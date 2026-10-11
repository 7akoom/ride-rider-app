/// What moved money in or out of the rider's wallet.
enum MovementKind {
  topUp,
  tripPayment,
  change,
  transferOut,
  transferIn,
  duePayment,
  voucher,
  refund,
  tip,
  adjustment,
  other,
}

/// One line of the wallet's history. Whole currency units; [amount] is signed:
/// negative means money left the wallet.
final class WalletMovement {
  const WalletMovement({
    required this.id,
    required this.kind,
    required this.amount,
    required this.at,
    this.balanceAfter,
    this.tripId = '',
  });

  final String id;
  final MovementKind kind;
  final int amount;
  final DateTime at;
  final int? balanceAfter;
  final String tripId;

  bool get isIn => amount > 0;
}
