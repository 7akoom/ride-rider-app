import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/error/failure_mapper.dart';
import 'package:rider_app/core/network/api_exception.dart';

ApiException _api({int? status, int? code, String? reason}) =>
    ApiException(statusCode: status, code: code, message: 'x', reason: reason);

void main() {
  group('mapToFailure', () {
    test('connection problems', () {
      expect(mapToFailure(const ApiException(message: 'x', isNetwork: true)),
          isA<NetworkFailure>());
      expect(
        mapToFailure(const ApiException(message: 'x', isNetwork: true, isTimeout: true)),
        isA<TimeoutFailure>(),
      );
      expect(mapToFailure(TimeoutException('slow')), isA<TimeoutFailure>());
    });

    test('the gRPC code wins over the HTTP status', () {
      expect(mapToFailure(_api(status: 400, code: 9)), isA<PreconditionFailure>());
      expect(mapToFailure(_api(status: 400, code: 3)), isA<InvalidInputFailure>());
      expect(mapToFailure(_api(status: 409, code: 6)), isA<ConflictFailure>());
      expect(mapToFailure(_api(status: 503, code: 14)), isA<ServerFailure>());
    });

    test('HTTP status when there is no gRPC code', () {
      expect(mapToFailure(_api(status: 401)), isA<SessionExpiredFailure>());
      expect(mapToFailure(_api(status: 403)), isA<ForbiddenFailure>());
      expect(mapToFailure(_api(status: 404)), isA<NotFoundFailure>());
      expect(mapToFailure(_api(status: 429)), isA<RateLimitedFailure>());
      expect(mapToFailure(_api(status: 502)), isA<ServerFailure>());
      expect(mapToFailure(_api(status: 504)), isA<TimeoutFailure>());
      expect(mapToFailure(_api(status: 302)), isA<UnexpectedFailure>());
    });

    test('keeps the backend reason', () {
      final failure = mapToFailure(_api(status: 400, code: 9, reason: 'RIDER_HAS_DUES'));

      expect((failure as PreconditionFailure).reason, 'RIDER_HAS_DUES');
    });

    test('Dio errors without an answer are network failures', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.connectionError,
      );

      expect(mapToFailure(error), isA<NetworkFailure>());
    });

    test('anything else is unexpected, and failures pass through', () {
      expect(mapToFailure(StateError('bug')), isA<UnexpectedFailure>());
      expect(mapToFailure(const NotFoundFailure()), isA<NotFoundFailure>());
    });
  });
}
