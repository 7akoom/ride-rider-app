import 'package:dio/dio.dart';

import '../security/session_storage.dart';
import 'dio_error_converter.dart';
import 'json.dart';

enum RefreshOutcome {
  /// New tokens are stored; the failed call can be repeated.
  refreshed,

  /// The refresh token was refused: the session is over.
  rejected,

  /// No answer (offline or a server error): the session may still be fine.
  unavailable,
}

/// Trades the refresh token for a new token pair.
///
/// Several calls can find the access token expired at the same moment; they all wait
/// for one refresh instead of each spending the single-use refresh token.
class TokenRefresher {
  TokenRefresher({required Dio dio, required this.languageCode}) : _dio = dio;

  /// A separate Dio from the one making normal calls, so a refresh never waits on itself.
  final Dio _dio;
  final String Function() languageCode;

  Future<RefreshOutcome>? _running;

  Future<RefreshOutcome> refresh() {
    final running = _running;
    if (running != null) {
      return running;
    }

    final attempt = _renew().whenComplete(() => _running = null);
    _running = attempt;

    return attempt;
  }

  Future<RefreshOutcome> _renew() async {
    final refreshToken = await SessionStorage.readRefreshToken();
    if (refreshToken == null) {
      return RefreshOutcome.rejected;
    }

    try {
      final response = await _dio.post<dynamic>(
        '/v1/auth/token:refresh',
        data: <String, dynamic>{'refreshToken': refreshToken},
        options: Options(headers: {'Accept-Language': languageCode()}),
      );

      return await _store(decodeJsonObject(response.data));
    } on DioException catch (error) {
      final failure = toApiException(error);

      return failure.isNetwork || failure.isServerError
          ? RefreshOutcome.unavailable
          : RefreshOutcome.rejected;
    }
  }

  Future<RefreshOutcome> _store(JsonMap json) async {
    final access = json['accessToken'];
    final refresh = json['refreshToken'];

    if (access is! String || refresh is! String) {
      return RefreshOutcome.rejected;
    }

    final identity = json['identityId'];

    await SessionStorage.saveTokens(
      accessToken: access,
      refreshToken: refresh,
      identityId: identity is String && identity.isNotEmpty
          ? identity
          : (await SessionStorage.readIdentityId()) ?? '',
    );

    return RefreshOutcome.refreshed;
  }
}
