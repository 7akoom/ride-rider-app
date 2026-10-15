import '../../../core/error/guard.dart';
import '../../../core/error/result.dart';
import '../../../core/network/json.dart';
import '../domain/entities/wallet_pin.dart';
import '../domain/repositories/wallet_pin_repository.dart';
import 'wallet_pin_api.dart';

final class WalletPinRepositoryImpl implements WalletPinRepository {
  WalletPinRepositoryImpl(this._api);

  final WalletPinApi _api;

  @override
  Future<Result<PinStatus>> status() => guard(() async => pinStatusOf(await _api.status()));

  @override
  Future<Result<PinCheck>> verify(String pin) => guard(() async => pinCheckOf(await _api.verify(pin)));

  @override
  Future<Result<PinStatus>> set({required String newPin, String? currentPin}) =>
      guard(() async => pinStatusOf(await _api.set(newPin: newPin, currentPin: currentPin)));
}

/// WalletPinStatusResponse in its JSON form: fields at their defaults are left out.
PinStatus pinStatusOf(JsonMap json) {
  final locked = json['lockedUntil'];
  final attempts = json['attemptsLeft'];

  return PinStatus(
    isSet: json['isSet'] == true,
    lockedUntil: locked is String ? DateTime.tryParse(locked)?.toLocal() : null,
    attemptsLeft: attempts is num ? attempts.toInt() : 0,
  );
}

/// VerifyWalletPinResponse in its JSON form (the enum by name).
PinCheck pinCheckOf(JsonMap json) {
  final locked = json['lockedUntil'];
  final attempts = json['attemptsLeft'];
  final result = switch (json['result']) {
    'PIN_CHECK_OK' => PinCheckResult.ok,
    'PIN_CHECK_LOCKED' => PinCheckResult.locked,
    'PIN_CHECK_NOT_SET' => PinCheckResult.notSet,
    'PIN_CHECK_WRONG' => PinCheckResult.wrong,
    _ => throw const FormatException('an unknown PIN check'),
  };

  return PinCheck(
    result,
    attemptsLeft: attempts is num ? attempts.toInt() : 0,
    lockedUntil: locked is String ? DateTime.tryParse(locked)?.toLocal() : null,
  );
}
