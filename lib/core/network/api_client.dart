import 'package:dio/dio.dart';

import '../security/session_storage.dart';
import 'api_exception.dart';
import 'dio_error_converter.dart';
import 'json.dart';
import 'token_refresher.dart';

export 'json.dart' show JsonMap;

/// Talks to the API gateway as the signed-in rider.
///
/// Every call carries the access token. When the backend answers 401 (the token ran out:
/// it lives 15 minutes), the client trades the refresh token for a new pair once and
/// repeats the call. If the refresh token is refused too, the session is over:
/// [onSessionExpired] runs and the caller gets the 401.
///
/// Every failure leaves this class as an [ApiException]; nothing from Dio escapes.
class ApiClient {
  ApiClient({
    required String baseUrl,
    required this.languageCode,
    this.onSessionExpired,
  }) : _dio = Dio(_options(baseUrl)) {
    _refresher = TokenRefresher(
      dio: Dio(_options(baseUrl)),
      languageCode: languageCode,
    );
  }

  final Dio _dio;
  late final TokenRefresher _refresher;

  /// The language the person picked ('ar', 'ku' or 'en'): the backend writes its own
  /// texts (for example the login code message) in it.
  final String Function() languageCode;

  final Future<void> Function()? onSessionExpired;

  static BaseOptions _options(String baseUrl) => BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      );

  /// [auth] false is for the login routes, which take no token.
  ///
  /// [signOutOnExpiry] false makes a refused refresh token throw instead of ending the
  /// session, for the check made when the app opens (it decides where to go itself).
  Future<JsonMap> get(
    String path, {
    Map<String, dynamic>? query,
    bool auth = true,
    bool signOutOnExpiry = true,
  }) =>
      _send('GET', path,
          query: query, auth: auth, signOutOnExpiry: signOutOnExpiry);

  Future<JsonMap> post(String path, {Object? body, bool auth = true}) =>
      _send('POST', path, body: body ?? const <String, dynamic>{}, auth: auth);

  Future<JsonMap> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body ?? const <String, dynamic>{});

  Future<JsonMap> put(String path, {Object? body}) =>
      _send('PUT', path, body: body ?? const <String, dynamic>{});

  Future<JsonMap> delete(String path) => _send('DELETE', path);

  Future<JsonMap> _send(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    bool auth = true,
    bool signOutOnExpiry = true,
  }) async {
    var alreadyRefreshed = false;

    while (true) {
      try {
        final response = await _dio.request<dynamic>(
          path,
          data: body,
          queryParameters: query,
          options: Options(method: method, headers: await _headers(auth)),
        );

        return decodeJsonObject(response.data);
      } on DioException catch (error) {
        final failure = toApiException(error);

        if (!auth || !failure.isUnauthorized || alreadyRefreshed) {
          throw failure;
        }

        alreadyRefreshed = true;

        switch (await _refresher.refresh()) {
          case RefreshOutcome.refreshed:
            continue;
          case RefreshOutcome.rejected:
            if (signOutOnExpiry) {
              await onSessionExpired?.call();
            }
            throw failure;
          case RefreshOutcome.unavailable:
            // The token may still be fine: there was just no way to find out. Do not
            // sign anyone out because their connection dropped.
            throw const ApiException(message: 'refresh unavailable', isNetwork: true);
        }
      }
    }
  }

  Future<Map<String, dynamic>> _headers(bool auth) async {
    final headers = <String, dynamic>{'Accept-Language': languageCode()};

    if (auth) {
      final token = await SessionStorage.readToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }
}
