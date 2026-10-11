import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/core/network/api_client.dart';
import 'package:rider_app/core/network/api_exception.dart';
import 'package:rider_app/features/booking/data/trip_end_api.dart';
import 'package:rider_app/features/booking/data/trip_end_repository_impl.dart';
import 'package:rider_app/features/booking/domain/entities/payment_method.dart';
import 'package:rider_app/features/booking/domain/entities/trip_payment.dart';
import 'package:rider_app/features/booking/domain/use_cases/finish_trip.dart';

class _FakeTripEndApi implements TripEndApi {
  JsonMap settled = {};
  Object? settlementError;
  Object? rateError;
  JsonMap? rated;
  JsonMap? tipped;

  @override
  Future<JsonMap> settlement(String riderId, String tripId) async =>
      settlementError == null ? settled : throw settlementError!;

  @override
  Future<JsonMap> rate(String tripId, JsonMap body) async {
    rated = body;

    return rateError == null ? {} : throw rateError!;
  }

  @override
  Future<JsonMap> tip(String riderId, String tripId, JsonMap body) async {
    tipped = body;

    return {};
  }
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({'rider_id': 'r1'}));

  test('a settlement is read with its tip and change; missing amounts are zero', () async {
    final api = _FakeTripEndApi()
      ..settled = {
        'paymentMethod': 'PAYMENT_METHOD_CASH',
        'fareAmount': '3000.00',
        'cashAmount': '3000',
        'changeAmount': '500',
        'tipAmount': '1000',
      };

    final payment = (await TripEndRepositoryImpl(api).payment('t1') as Ok<TripPayment?>).value!;

    expect(payment.method, PaymentMethod.cash);
    expect(payment.fare, 3000);
    expect(payment.change, 500);
    expect(payment.fromWallet, 0);
    expect(payment.total, 4000);
  });

  test('a trip not settled yet is no payment, not a failure', () async {
    final api = _FakeTripEndApi()
      ..settlementError = const ApiException(statusCode: 404, code: 5, message: 'not yet');

    expect((await TripEndRepositoryImpl(api).payment('t1') as Ok<TripPayment?>).value, isNull);
  });

  test('the rider rates the captain; rated already is done', () async {
    final api = _FakeTripEndApi()
      ..rateError = const ApiException(statusCode: 409, code: 6, message: 'already rated');

    final result = await TripEndRepositoryImpl(api).rate('t1', 5, 'Kind');

    expect(result, isA<Ok<void>>());
    expect(api.rated, {'ratedBy': 'RATED_BY_RIDER', 'stars': 5, 'comment': 'Kind'});
  });

  test('a tip goes with its key, as a decimal amount', () async {
    final api = _FakeTripEndApi();

    await TripEndRepositoryImpl(api).tip('t1', 1000, 'tip-t1');

    expect(api.tipped, {'amount': '1000', 'idempotencyKey': 'tip-t1'});
  });

  test('a tip within the limits and the wallet goes', () {
    expect(TipCaptain.problemOf(100, 5000), TipProblem.tooSmall);
    expect(TipCaptain.problemOf(30000, 50000), TipProblem.tooBig);
    expect(TipCaptain.problemOf(2000, 1000), TipProblem.notEnoughMoney);
    expect(TipCaptain.problemOf(1000, 1000), isNull);
  });
}
