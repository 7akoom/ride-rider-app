import 'dart:math' as math;

/// A random key of [bytes] bytes as hex, from the system's secure source (request
/// idempotency keys: a retry sends the same one).
String randomKey({int bytes = 16}) {
  final random = math.Random.secure();

  return List.generate(bytes, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
}
