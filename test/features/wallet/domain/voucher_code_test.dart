import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/features/wallet/domain/entities/voucher_code.dart';
import 'package:rider_app/features/wallet/domain/use_cases/redeem_voucher.dart';

import '../fake_wallet.dart';

void main() {
  test('a code is read however it is typed or pasted', () {
    expect(VoucherCode.clean('abcd-efgh jkmn-pqrs'), 'ABCDEFGHJKMNPQRS');
    expect(VoucherCode.isComplete(' ABCD EFGH-JKMN PQRS '), isTrue);
    expect(VoucherCode.isComplete('ABCD-EFGH'), isFalse);
    expect(VoucherCode.isWrong('ABCD-EFGH'), isFalse);
  });

  test('characters no code has, and too many, are wrong', () {
    expect(VoucherCode.isWrong('ABCD-EFGH-JKMN-PQR0'), isTrue); // 0 is never in a code
    expect(VoucherCode.isWrong('ABCD-EFGH-JKMN-PQRS-T'), isTrue);
    expect(VoucherCode.isWrong('قسيمة'), isTrue);
  });

  test('only a whole code reaches the wallet, without dashes', () async {
    final wallet = FakeWallet();
    final redeem = RedeemVoucher(wallet);

    expect(await redeem('ABCD-EFGH'), isA<Err<Object>>());
    expect((await redeem('ABCD-EFGH') as Err).failure, isA<InvalidInputFailure>());
    expect(wallet.redeemed, isEmpty);

    expect(await redeem('abcd-efgh-jkmn-pqrs'), isA<Ok<Object>>());
    expect(wallet.redeemed, ['ABCDEFGHJKMNPQRS']);
  });
}
