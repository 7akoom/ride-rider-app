import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/locale_provider.dart';
import '../config/app_env.dart';
import '../security/session_storage.dart';
import 'api_client.dart';

/// The one connection to the backend. There must be only one: it owns the token
/// refresher, and two refreshers would both spend the single-use refresh token.
final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    baseUrl: AppEnv.apiBaseUrl,
    languageCode: () => ref.read(localeProvider).languageCode,
    onSessionExpired: () async {
      await SessionStorage.clear();
      ref.read(sessionEndedProvider.notifier).state++;
    },
  );
});

/// Goes up by one each time the backend ends the session (the refresh token was
/// refused), wherever the rider is. The app listens to it and returns to sign-in.
final StateProvider<int> sessionEndedProvider = StateProvider<int>((ref) => 0);
