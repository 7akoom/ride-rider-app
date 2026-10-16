import '../entities/biometric.dart';

/// Paying with a fingerprint or the face: the wallet PIN is kept in the phone's
/// secure storage, and given back only after the phone confirms the rider. The server
/// still checks the PIN as if it were typed.
abstract interface class BiometricPinRepository {
  /// What the phone can confirm with; null when it has none set up.
  Future<BiometricKind?> available();

  /// Shows the phone's own prompt with [reason]; true when the rider was confirmed.
  Future<bool> confirm(String reason);

  /// The PIN kept for the signed-in rider; null when paying this way is off.
  Future<String?> kept();

  Future<void> keep(String pin);

  Future<void> forget();
}
