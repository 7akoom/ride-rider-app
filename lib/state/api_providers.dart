import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_exception.dart';
import '../core/api/auth_api.dart';
import '../core/api/maps_api.dart';
import '../core/api/money_api.dart';
import '../core/api/notifications_api.dart';
import '../core/api/rider_api.dart';
import '../core/api/trip_api.dart';
import '../core/models/rider_profile.dart';
import '../core/network/api_client_provider.dart';
import 'session_storage.dart';

final Provider<AuthApi> authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(apiClientProvider));
});

final Provider<RiderApi> riderApiProvider = Provider<RiderApi>((ref) {
  return RiderApi(ref.watch(apiClientProvider));
});

final Provider<TripApi> tripApiProvider = Provider<TripApi>((ref) {
  return TripApi(ref.watch(apiClientProvider));
});

final Provider<MapsApi> mapsApiProvider = Provider<MapsApi>((ref) {
  return MapsApi(ref.watch(apiClientProvider));
});

final Provider<MoneyApi> moneyApiProvider = Provider<MoneyApi>((ref) {
  return MoneyApi(ref.watch(apiClientProvider));
});

final Provider<NotificationsApi> notificationsApiProvider = Provider<NotificationsApi>((ref) {
  return NotificationsApi(ref.watch(apiClientProvider));
});

/// The signed-in rider's profile (null if there is none yet).
final FutureProvider<RiderProfile?> riderProfileProvider = FutureProvider<RiderProfile?>((ref) async {
  final identityId = await SessionStorage.readIdentityId();
  if (identityId == null) {
    return null;
  }

  return ref.watch(riderApiProvider).getByIdentity(identityId);
});

/// The signed-in rider's verified phone number, in international form.
final FutureProvider<String?> myPhoneProvider = FutureProvider<String?>((ref) async {
  final me = await ref.watch(authApiProvider).getMyIdentity();

  return me.phone;
});

/// Where a person stands once they have a session.
enum AccountState {
  /// No session, or the backend refused it.
  signedOut,

  /// Signed in, but has not made a rider profile yet.
  needsProfile,

  /// Signed in with a profile: straight to the app.
  ready,
}

final Provider<AccountService> accountServiceProvider = Provider<AccountService>((ref) {
  return AccountService(ref.watch(riderApiProvider));
});

class AccountService {
  AccountService(this._riders);

  final RiderApi _riders;

  /// Finds out whether the stored session still works and whether the rider has a profile.
  ///
  /// It throws [ApiException] (with isNetwork) when the backend cannot be reached: that
  /// is not a reason to sign anyone out.
  Future<AccountState> resolve() async {
    final identityId = await SessionStorage.readIdentityId();
    final refreshToken = await SessionStorage.readRefreshToken();

    if (identityId == null || refreshToken == null) {
      return AccountState.signedOut;
    }

    try {
      final profile = await _riders.getByIdentity(
        identityId,
        signOutOnExpiry: false,
      );

      if (profile == null) {
        return AccountState.needsProfile;
      }

      await SessionStorage.saveRiderId(profile.id);

      return AccountState.ready;
    } on ApiException catch (error) {
      // The token and its refresh were both refused: the login is over.
      if (error.isUnauthorized) {
        await SessionStorage.clear();

        return AccountState.signedOut;
      }

      rethrow;
    }
  }
}

/// Signs out: tells the backend (best effort), forgets the session on the phone, and
/// returns to the phone number screen.
Future<void> signOut(WidgetRef ref) async {
  final refreshToken = await SessionStorage.readRefreshToken();

  if (refreshToken != null) {
    try {
      await ref.read(authApiProvider).logout(refreshToken);
    } catch (_) {
      // Signing out must work with no connection too.
    }
  }

  await SessionStorage.clear();

  // The app listens to this: it clears the cached profile and opens the phone screen.
  ref.read(sessionEndedProvider.notifier).state++;
}
