/// The rider's wallet at a glance: its balance, and fees of cancelled trips still owed
/// (the next money that reaches the wallet pays them first).
final class WalletOverview {
  const WalletOverview({required this.balance, this.owed = 0, this.canRequestTrips = true});

  final int balance;
  final int owed;

  /// False while fees are owed and the platform blocks trips until they are paid.
  final bool canRequestTrips;
}
