import 'wallet_movement.dart';

/// Which movements a list shows.
enum MovementFilter { all, moneyIn, moneyOut, tips, refunds }

/// A period of the wallet: its movements newest first, a page at a time, and what
/// the period adds up to.
final class StatementPage {
  const StatementPage({
    required this.movements,
    required this.opening,
    required this.closing,
    required this.totalIn,
    required this.totalOut,
    this.next,
  });

  final List<WalletMovement> movements;
  final int opening;
  final int closing;

  /// Both positive, of the movements the filter keeps.
  final int totalIn;
  final int totalOut;

  /// Where the next page starts; null on the last one.
  final String? next;
}
