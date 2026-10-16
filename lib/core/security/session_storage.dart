import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// What the app remembers about who is signed in, in the phone's secure storage.
///
/// The access token lives 15 minutes; the refresh token is what keeps the person signed
/// in (ApiClient trades it for a new pair when the access token runs out). The device id
/// is made once per install and survives a sign-out, so the backend sees the same device
/// on the next login.
class SessionStorage {
  static const _storage = FlutterSecureStorage();

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _identityKey = 'identity_id';
  static const _riderKey = 'rider_id';
  static const _deviceKey = 'device_id';
  static const _walletPinKey = 'wallet_pin';

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String identityId,
  }) async {
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);

    if (identityId.isNotEmpty) {
      await _storage.write(key: _identityKey, value: identityId);
    }
  }

  static Future<String?> readToken() => _storage.read(key: _accessKey);

  static Future<String?> readRefreshToken() => _storage.read(key: _refreshKey);

  static Future<String?> readIdentityId() => _storage.read(key: _identityKey);

  static Future<String?> readRiderId() => _storage.read(key: _riderKey);

  static Future<void> saveRiderId(String riderId) =>
      _storage.write(key: _riderKey, value: riderId);

  /// A random id for this install, made on first use.
  static Future<String> deviceId() async {
    final existing = await _storage.read(key: _deviceKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final id = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    await _storage.write(key: _deviceKey, value: id);

    return id;
  }

  /// The wallet PIN kept for paying with a fingerprint or the face, with the identity
  /// it belongs to; null when it is not kept (or kept for someone else).
  static Future<String?> readWalletPin() async {
    final identity = await readIdentityId();
    final kept = await _storage.read(key: _walletPinKey);

    if (identity == null || kept == null || !kept.startsWith('$identity:')) {
      return null;
    }

    return kept.substring(identity.length + 1);
  }

  static Future<void> saveWalletPin(String pin) async {
    final identity = await readIdentityId();

    if (identity != null) {
      await _storage.write(key: _walletPinKey, value: '$identity:$pin');
    }
  }

  static Future<void> deleteWalletPin() => _storage.delete(key: _walletPinKey);

  /// Forgets the signed-in person. The device id stays.
  static Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _identityKey);
    await _storage.delete(key: _riderKey);
    await _storage.delete(key: _walletPinKey);
  }
}
