/// What the phone confirms the rider with, in place of typing the wallet PIN.
enum BiometricKind { fingerprint, face }

/// Whether the phone can confirm payments with [kind] (null: it cannot), and whether
/// the rider turned it on.
final class BiometricState {
  const BiometricState({this.kind, this.enabled = false});

  final BiometricKind? kind;
  final bool enabled;

  bool get available => kind != null;
}
