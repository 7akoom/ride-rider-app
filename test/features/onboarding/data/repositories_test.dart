import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/core/network/api_client.dart';
import 'package:rider_app/core/network/api_exception.dart';
import 'package:rider_app/core/phone/phone_number.dart';
import 'package:rider_app/core/rider/display_name.dart';
import 'package:rider_app/core/rider/rider_account_api.dart';
import 'package:rider_app/core/rider/rider_account_repository_impl.dart';
import 'package:rider_app/core/security/session_storage.dart';
import 'package:rider_app/features/onboarding/data/client_info.dart';
import 'package:rider_app/features/onboarding/data/sign_in_api.dart';
import 'package:rider_app/features/onboarding/data/sign_in_repository_impl.dart';
import 'package:rider_app/features/onboarding/domain/entities/otp_challenge.dart';
import 'package:rider_app/features/onboarding/domain/values/otp_code.dart';

class _SignInApi implements SignInApi {
  JsonMap answer = {};
  Object? error;

  @override
  Future<JsonMap> requestCode(String e164Phone) async => error == null ? answer : throw error!;

  @override
  Future<JsonMap> verifyCode({
    required String challengeId,
    required String code,
    required String deviceId,
    required ClientInfo client,
  }) async =>
      error == null ? answer : throw error!;
}

class _RiderApi implements RiderAccountApi {
  Object? findError;
  Object? createError;
  JsonMap rider = {
    'rider': {'id': 'r1', 'displayName': 'Salem'},
  };

  @override
  Future<JsonMap> findByIdentity(String identityId) async =>
      findError == null ? rider : throw findError!;

  @override
  Future<JsonMap> create({required String identityId, required String displayName}) async =>
      createError == null ? rider : throw createError!;
}

Failure? _failureOf<T>(Result<T> result) => result.fold((_) => null, (f) => f);

final _phone = PhoneNumber.tryParse('07701234567')!;
final _challenge = OtpChallenge(id: 'c1', phone: _phone, expiresIn: const Duration(minutes: 5));
final _code = OtpCode.tryParse('123456')!;

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('SignInRepositoryImpl', () {
    test('sending a code returns the challenge', () async {
      final api = _SignInApi()..answer = {'challengeId': 'c9', 'expiresInSeconds': 300};
      final result = await SignInRepositoryImpl(api).sendCode(_phone);

      final challenge = result.fold((v) => v, (_) => null)!;
      expect(challenge.id, 'c9');
      expect(challenge.expiresIn, const Duration(minutes: 5));
    });

    test('a backend refusal becomes a failure, never an exception', () async {
      final api = _SignInApi()
        ..error = const ApiException(statusCode: 429, code: 8, message: 'rate limit');

      expect(_failureOf(await SignInRepositoryImpl(api).sendCode(_phone)), isA<RateLimitedFailure>());
    });

    test('an accepted code stores the whole session', () async {
      final api = _SignInApi()
        ..answer = {'identityId': 'i1', 'accessToken': 'a', 'refreshToken': 'r'};
      final repo = SignInRepositoryImpl(api);

      expect(await repo.confirmCode(_challenge, _code), isA<Ok<void>>());
      expect(await SessionStorage.readIdentityId(), 'i1');
      expect(await repo.hasSession(), isTrue);
    });

    test('an incomplete answer stores nothing', () async {
      final api = _SignInApi()..answer = {'identityId': 'i1', 'accessToken': 'a'};
      final repo = SignInRepositoryImpl(api);

      expect(_failureOf(await repo.confirmCode(_challenge, _code)), isA<UnexpectedFailure>());
      expect(await repo.hasSession(), isFalse);
    });

    test('forgetting keeps the device id', () async {
      final device = await SessionStorage.deviceId();
      final api = _SignInApi()
        ..answer = {'identityId': 'i1', 'accessToken': 'a', 'refreshToken': 'r'};
      final repo = SignInRepositoryImpl(api);
      await repo.confirmCode(_challenge, _code);

      await repo.forgetSession();

      expect(await repo.hasSession(), isFalse);
      expect(await SessionStorage.deviceId(), device);
    });
  });

  group('RiderAccountRepositoryImpl', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({'identity_id': 'i1'}));

    test('finds the profile and remembers the rider id', () async {
      final result = await RiderAccountRepositoryImpl(_RiderApi()).findMine();

      expect(result.fold((v) => v?.id, (_) => null), 'r1');
      expect(await SessionStorage.readRiderId(), 'r1');
    });

    test('no profile yet is Ok(null)', () async {
      final api = _RiderApi()
        ..findError = const ApiException(statusCode: 404, code: 5, message: 'not found');
      final result = await RiderAccountRepositoryImpl(api).findMine();

      expect(result, isA<Ok<dynamic>>());
      expect(result.fold((v) => v, (_) => 'failed'), isNull);
    });

    test('no stored identity is a refused session', () async {
      FlutterSecureStorage.setMockInitialValues({});

      expect(
        _failureOf(await RiderAccountRepositoryImpl(_RiderApi()).findMine()),
        isA<SessionExpiredFailure>(),
      );
    });

    test('creating one that already exists returns the existing one', () async {
      final api = _RiderApi()
        ..createError = const ApiException(statusCode: 409, code: 6, message: 'exists');
      final result = await RiderAccountRepositoryImpl(api).create(DisplayName.tryParse('Salem')!);

      expect(result.fold((v) => v.id, (_) => null), 'r1');
    });
  });
}
