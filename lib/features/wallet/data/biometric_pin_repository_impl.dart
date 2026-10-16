import 'package:local_auth/local_auth.dart';

import '../../../core/security/session_storage.dart';
import '../domain/entities/biometric.dart';
import '../domain/repositories/biometric_pin_repository.dart';

/// The phone's fingerprint or face check (local_auth), and the PIN in secure storage.
class BiometricPinRepositoryImpl implements BiometricPinRepository {
  BiometricPinRepositoryImpl([LocalAuthentication? auth]) : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<BiometricKind?> available() async {
    try {
      if (!await _auth.isDeviceSupported() || !await _auth.canCheckBiometrics) {
        return null;
      }

      final types = await _auth.getAvailableBiometrics();

      if (types.isEmpty) {
        // Supported, but nothing enrolled yet.
        return null;
      }

      // Android often says only strong/weak: a fingerprint is the likely one.
      final faceOnly = types.contains(BiometricType.face) && !types.contains(BiometricType.fingerprint);

      return faceOnly ? BiometricKind.face : BiometricKind.fingerprint;
    } on Exception {
      return null;
    }
  }

  @override
  Future<bool> confirm(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
    } on Exception {
      // Cancelled, locked out after many tries, or nothing enrolled any more.
      return false;
    }
  }

  @override
  Future<String?> kept() => SessionStorage.readWalletPin();

  @override
  Future<void> keep(String pin) => SessionStorage.saveWalletPin(pin);

  @override
  Future<void> forget() => SessionStorage.deleteWalletPin();
}
