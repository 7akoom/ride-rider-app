/// A failed call to the backend, as the network layer sees it.
///
/// This never reaches a screen: the data layer turns it into a `Failure`
/// (lib/core/error) and the rider only ever sees that failure's translated message.
class ApiException implements Exception {
  const ApiException({
    this.statusCode,
    this.code,
    required this.message,
    this.reason,
    this.isNetwork = false,
    this.isTimeout = false,
  });

  /// The HTTP status, or null when there was no answer at all.
  final int? statusCode;

  /// The gRPC code the backend answered with, when it said one.
  final int? code;

  /// The backend's own message (English, for developers; never shown to riders).
  final String message;

  /// A stable machine-readable reason from the backend's error details, when present.
  final String? reason;

  /// True when the request never got an answer: no connection, or it timed out.
  final bool isNetwork;

  /// True when the request timed out (a special case of [isNetwork]).
  final bool isTimeout;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
  bool get isTooManyRequests => statusCode == 429;
  bool get isServerError => statusCode != null && statusCode! >= 500;

  @override
  String toString() => 'ApiException(${statusCode ?? 'no answer'}, code: $code)';
}
