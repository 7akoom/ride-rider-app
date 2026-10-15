/// Whether the rider has a wallet PIN, and whether wrong PINs locked it. The PIN
/// confirms money leaving the wallet (a transfer, paying a request); identity-service
/// keeps it, like the phone the rider signs in with.
final class PinStatus {
  const PinStatus({required this.isSet, this.lockedUntil, this.attemptsLeft = 5});

  final bool isSet;

  /// Set while wrong PINs keep it locked.
  final DateTime? lockedUntil;

  /// Wrong PINs left before it locks.
  final int attemptsLeft;

  bool lockedAt(DateTime now) => lockedUntil?.isAfter(now) ?? false;
}

/// What checking the rider's own PIN said.
enum PinCheckResult { ok, wrong, locked, notSet }

final class PinCheck {
  const PinCheck(this.result, {this.attemptsLeft = 0, this.lockedUntil});

  final PinCheckResult result;

  /// Wrong PINs left before it locks (after a wrong one).
  final int attemptsLeft;

  /// Until when it is locked (when locked).
  final DateTime? lockedUntil;
}

/// The rules a new PIN follows, checked here before the server is asked (it checks
/// the same): four digits, not all the same and not a straight run up or down.
abstract final class WalletPin {
  static const int length = 4;

  static final RegExp _digits = RegExp(r'^[0-9]+$');

  static bool isComplete(String pin) => pin.length == length && _digits.hasMatch(pin);

  /// True for 1111, 1234, 4321 and the like.
  static bool isWeak(String pin) {
    if (!isComplete(pin)) {
      return true;
    }

    var same = true;
    var up = true;
    var down = true;

    for (var i = 1; i < pin.length; i++) {
      final step = pin.codeUnitAt(i) - pin.codeUnitAt(i - 1);
      same = same && step == 0;
      up = up && step == 1;
      down = down && step == -1;
    }

    return same || up || down;
  }
}
