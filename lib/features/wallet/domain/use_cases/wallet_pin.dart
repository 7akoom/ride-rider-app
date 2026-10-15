import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/wallet_pin.dart';
import '../repositories/wallet_pin_repository.dart';

/// Whether the rider has a wallet PIN, and whether it is locked.
final class LoadPinStatus {
  const LoadPinStatus(this.pins);

  final WalletPinRepository pins;

  Future<Result<PinStatus>> call() => pins.status();
}

/// Checks the PIN the rider typed before going on (the current one, on a change).
final class VerifyWalletPin {
  const VerifyWalletPin(this.pins);

  final WalletPinRepository pins;

  Future<Result<PinCheck>> call(String pin) => pins.verify(pin);
}

/// Sets a new wallet PIN. A weak one (1111, 1234) is refused here, before the server
/// is asked.
final class SetWalletPin {
  const SetWalletPin(this.pins);

  final WalletPinRepository pins;

  Future<Result<PinStatus>> call({required String newPin, String? currentPin}) async {
    if (WalletPin.isWeak(newPin)) {
      return const Err(InvalidInputFailure());
    }

    return pins.set(newPin: newPin, currentPin: currentPin);
  }
}
