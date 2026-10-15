import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/features/wallet/data/wallet_pin_repository_impl.dart';
import 'package:rider_app/features/wallet/domain/entities/wallet_pin.dart';
import 'package:rider_app/features/wallet/domain/use_cases/wallet_pin.dart';

import '../fake_wallet.dart';

void main() {
  test('a PIN is four digits, not all the same and not a straight run', () {
    for (final weak in ['1111', '1234', '4321', '6789', '9876', '0000', '123', '12345', '12a4', '']) {
      expect(WalletPin.isWeak(weak), isTrue, reason: weak);
    }

    for (final good in ['2580', '1357', '1123', '9901', '4826']) {
      expect(WalletPin.isWeak(good), isFalse, reason: good);
    }
  });

  test('a weak PIN never reaches the server', () async {
    final pins = FakeWalletPin();
    final result = await SetWalletPin(pins).call(newPin: '1234');

    expect(result, isA<Err<PinStatus>>());
    expect((result as Err<PinStatus>).failure, isA<InvalidInputFailure>());
    expect(pins.sets, isEmpty);

    expect(await SetWalletPin(pins).call(newPin: '2580'), isA<Ok<PinStatus>>());
    expect(pins.sets, [('2580', null)]);
  });

  test('the status reads the JSON with its defaults left out', () {
    final none = pinStatusOf(const {});
    expect((none.isSet, none.lockedUntil, none.attemptsLeft), (false, null, 0));

    final locked = pinStatusOf(const {'isSet': true, 'lockedUntil': '2026-10-15T10:30:00Z', 'attemptsLeft': 0});
    expect(locked.isSet, isTrue);
    expect(locked.lockedUntil, DateTime.utc(2026, 10, 15, 10, 30).toLocal());
    expect(locked.lockedAt(DateTime.utc(2026, 10, 15, 10, 0)), isTrue);
    expect(locked.lockedAt(DateTime.utc(2026, 10, 15, 11, 0)), isFalse);

    final set = pinStatusOf(const {'isSet': true, 'setAt': '2026-10-15T09:00:00Z', 'attemptsLeft': 5});
    expect((set.isSet, set.lockedUntil, set.attemptsLeft), (true, null, 5));
  });

  test('a check reads the enum by name', () {
    expect(pinCheckOf(const {'result': 'PIN_CHECK_OK', 'attemptsLeft': 5}).result, PinCheckResult.ok);
    expect(pinCheckOf(const {'result': 'PIN_CHECK_NOT_SET'}).result, PinCheckResult.notSet);

    final wrong = pinCheckOf(const {'result': 'PIN_CHECK_WRONG', 'attemptsLeft': 3});
    expect((wrong.result, wrong.attemptsLeft), (PinCheckResult.wrong, 3));

    final locked = pinCheckOf(const {'result': 'PIN_CHECK_LOCKED', 'lockedUntil': '2026-10-15T10:30:00Z'});
    expect(locked.result, PinCheckResult.locked);
    expect(locked.lockedUntil, DateTime.utc(2026, 10, 15, 10, 30).toLocal());

    expect(() => pinCheckOf(const {}), throwsFormatException);
  });
}
