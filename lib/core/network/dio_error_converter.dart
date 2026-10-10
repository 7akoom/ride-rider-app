import 'package:dio/dio.dart';

import 'api_exception.dart';
import 'json.dart';

const Set<DioExceptionType> _timeouts = {
  DioExceptionType.connectionTimeout,
  DioExceptionType.sendTimeout,
  DioExceptionType.receiveTimeout,
};

/// Turns what Dio threw into an [ApiException].
///
/// The backend answers errors as `{code, message, details}` (grpc-gateway). A
/// `details` entry that carries a `reason` (google.rpc.ErrorInfo) gives features a
/// stable key to pick a more specific message.
ApiException toApiException(DioException error) {
  final response = error.response;

  if (response == null) {
    return ApiException(
      message: error.type.name,
      isNetwork: true,
      isTimeout: _timeouts.contains(error.type),
    );
  }

  final body = decodeJsonObject(response.data);
  final rawCode = body['code'];
  final rawMessage = body['message'];

  return ApiException(
    statusCode: response.statusCode,
    code: rawCode is num ? rawCode.toInt() : null,
    message: rawMessage is String && rawMessage.isNotEmpty
        ? rawMessage
        : 'HTTP ${response.statusCode}',
    reason: _reasonFrom(body['details']),
  );
}

String? _reasonFrom(Object? details) {
  if (details is! List) {
    return null;
  }

  for (final entry in details) {
    if (entry is Map && entry['reason'] is String) {
      return entry['reason'] as String;
    }
  }

  return null;
}
