import 'dart:async';

import 'package:dio/dio.dart';

import '../network/api_exception.dart';
import '../network/dio_error_converter.dart';
import 'failure.dart';

// gRPC status codes the gateway passes through in the `code` field.
const int _grpcInvalidArgument = 3;
const int _grpcDeadlineExceeded = 4;
const int _grpcNotFound = 5;
const int _grpcAlreadyExists = 6;
const int _grpcPermissionDenied = 7;
const int _grpcResourceExhausted = 8;
const int _grpcFailedPrecondition = 9;
const int _grpcAborted = 10;
const int _grpcOutOfRange = 11;
const int _grpcUnavailable = 14;
const int _grpcUnauthenticated = 16;

/// Turns anything that was thrown into a [Failure]. Never throws.
Failure mapToFailure(Object error) {
  return switch (error) {
    final Failure failure => failure,
    final ApiException apiError => _fromApi(apiError),
    final DioException dioError => _fromApi(toApiException(dioError)),
    TimeoutException() => const TimeoutFailure(),
    _ => const UnexpectedFailure(),
  };
}

Failure _fromApi(ApiException e) {
  if (e.isTimeout) {
    return const TimeoutFailure();
  }

  if (e.isNetwork) {
    return const NetworkFailure();
  }

  return _fromGrpcCode(e.code, e.reason) ?? _fromStatus(e.statusCode, e.reason);
}

// The gRPC code is more precise than the HTTP status: the gateway answers 400 for both
// InvalidArgument and FailedPrecondition.
Failure? _fromGrpcCode(int? code, String? reason) {
  return switch (code) {
    _grpcInvalidArgument || _grpcOutOfRange => InvalidInputFailure(reason: reason),
    _grpcFailedPrecondition => PreconditionFailure(reason: reason),
    _grpcNotFound => NotFoundFailure(reason: reason),
    _grpcAlreadyExists || _grpcAborted => ConflictFailure(reason: reason),
    _grpcPermissionDenied => ForbiddenFailure(reason: reason),
    _grpcUnauthenticated => SessionExpiredFailure(reason: reason),
    _grpcResourceExhausted => RateLimitedFailure(reason: reason),
    _grpcDeadlineExceeded => const TimeoutFailure(),
    _grpcUnavailable => ServerFailure(reason: reason),
    _ => null,
  };
}

Failure _fromStatus(int? status, String? reason) {
  return switch (status) {
    401 => SessionExpiredFailure(reason: reason),
    403 => ForbiddenFailure(reason: reason),
    404 => NotFoundFailure(reason: reason),
    409 => ConflictFailure(reason: reason),
    429 => RateLimitedFailure(reason: reason),
    400 || 422 => InvalidInputFailure(reason: reason),
    504 => const TimeoutFailure(),
    final int s when s >= 500 => ServerFailure(reason: reason),
    _ => const UnexpectedFailure(),
  };
}
