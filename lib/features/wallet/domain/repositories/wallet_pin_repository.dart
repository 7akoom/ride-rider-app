import '../../../../core/error/result.dart';
import '../entities/wallet_pin.dart';

/// The signed-in person's wallet PIN.
abstract interface class WalletPinRepository {
  Future<Result<PinStatus>> status();

  /// Checks [pin] against the rider's own. A wrong one counts toward the lock, like
  /// a wrong one on a transfer.
  Future<Result<PinCheck>> verify(String pin);

  /// Sets [newPin]. Changing it takes [currentPin], unless the rider signed in again
  /// moments ago (a forgotten PIN). A wrong current PIN is a ForbiddenFailure; a locked
  /// PIN or a missing current one is a PreconditionFailure; a weak PIN is an
  /// InvalidInputFailure.
  Future<Result<PinStatus>> set({required String newPin, String? currentPin});
}
