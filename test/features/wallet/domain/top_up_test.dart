import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/features/wallet/domain/entities/top_up.dart';
import 'package:rider_app/features/wallet/domain/use_cases/top_up.dart';

import '../fake_wallet.dart';

void main() {
  const options = TopUpOptions(min: 1000, max: 100000, providers: [TopUpOptions.zainCash]);

  test('an amount is within the limits or says why not', () {
    expect(options.problemOf(999), TopUpAmountProblem.tooSmall);
    expect(options.problemOf(100001), TopUpAmountProblem.tooBig);
    expect(options.problemOf(1000), isNull);
    expect(options.problemOf(100000), isNull);
  });

  test('only an amount within the limits, where ZainCash is set up, reaches the server', () async {
    final wallet = FakeWallet();
    final start = StartTopUp(wallet);

    final small = await start(amount: 500, options: options, language: 'ar');
    expect((small as Err).failure, isA<InvalidInputFailure>());

    const none = TopUpOptions(min: 1000, max: 100000);
    final off = await start(amount: 5000, options: none, language: 'ar');
    expect((off as Err).failure, isA<PreconditionFailure>());
    expect(wallet.startedTopUps, isEmpty);

    expect(await start(amount: 5000, options: options, language: 'ku'), isA<Ok<TopUpStart>>());
    expect(wallet.startedTopUps, [(5000, 'ku')]);
  });
}
