import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client_provider.dart';
import 'data/biometric_pin_repository_impl.dart';
import 'data/money_request_api.dart';
import 'data/money_request_repository_impl.dart';
import 'data/transfer_api.dart';
import 'data/transfer_repository_impl.dart';
import 'data/wallet_api.dart';
import 'data/wallet_pin_api.dart';
import 'data/wallet_pin_repository_impl.dart';
import 'data/wallet_repository_impl.dart';
import 'domain/repositories/biometric_pin_repository.dart';
import 'domain/repositories/money_request_repository.dart';
import 'domain/repositories/transfer_repository.dart';
import 'domain/repositories/wallet_pin_repository.dart';
import 'domain/repositories/wallet_repository.dart';
import 'domain/use_cases/follow_wallet.dart';
import 'domain/use_cases/money_requests.dart';
import 'domain/use_cases/redeem_voucher.dart';
import 'domain/use_cases/send_money.dart';
import 'domain/use_cases/top_up.dart';
import 'domain/use_cases/wallet_pin.dart';

// The wallet feature's wiring: the one file that knows both the data classes and the
// domain interfaces. Tests override walletRepositoryProvider.

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => WalletRepositoryImpl(WalletApi(ref.watch(apiClientProvider))),
);

final loadWalletProvider = Provider<LoadWallet>((ref) => LoadWallet(ref.watch(walletRepositoryProvider)));

final loadStatementProvider = Provider<LoadStatement>(
  (ref) => LoadStatement(ref.watch(walletRepositoryProvider)),
);

final redeemVoucherProvider = Provider<RedeemVoucher>(
  (ref) => RedeemVoucher(ref.watch(walletRepositoryProvider)),
);

final loadTopUpOptionsProvider = Provider<LoadTopUpOptions>(
  (ref) => LoadTopUpOptions(ref.watch(walletRepositoryProvider)),
);

final startTopUpProvider = Provider<StartTopUp>((ref) => StartTopUp(ref.watch(walletRepositoryProvider)));

final checkTopUpProvider = Provider<CheckTopUp>((ref) => CheckTopUp(ref.watch(walletRepositoryProvider)));

// The wallet PIN (identity-service). Tests override walletPinRepositoryProvider.

final walletPinRepositoryProvider = Provider<WalletPinRepository>(
  (ref) => WalletPinRepositoryImpl(WalletPinApi(ref.watch(apiClientProvider))),
);

final loadPinStatusProvider = Provider<LoadPinStatus>((ref) => LoadPinStatus(ref.watch(walletPinRepositoryProvider)));

final setWalletPinProvider = Provider<SetWalletPin>((ref) => SetWalletPin(ref.watch(walletPinRepositoryProvider)));

final verifyWalletPinProvider = Provider<VerifyWalletPin>(
  (ref) => VerifyWalletPin(ref.watch(walletPinRepositoryProvider)),
);

// Paying with a fingerprint or the face instead of typing the PIN. Tests override it.

final biometricPinProvider = Provider<BiometricPinRepository>((ref) => BiometricPinRepositoryImpl());

// Sending money to other riders. Tests override transferRepositoryProvider.

final transferRepositoryProvider = Provider<TransferRepository>(
  (ref) => TransferRepositoryImpl(TransferApi(ref.watch(apiClientProvider))),
);

final loadTransferOptionsProvider = Provider<LoadTransferOptions>(
  (ref) => LoadTransferOptions(ref.watch(transferRepositoryProvider)),
);

final lookupRecipientProvider = Provider<LookupRecipient>((ref) => LookupRecipient(ref.watch(transferRepositoryProvider)));

final loadRecentRecipientsProvider = Provider<LoadRecentRecipients>(
  (ref) => LoadRecentRecipients(ref.watch(transferRepositoryProvider)),
);

final sendMoneyProvider = Provider<SendMoney>((ref) => SendMoney(ref.watch(transferRepositoryProvider)));

// Asking for money and paying what others ask. Tests override moneyRequestRepositoryProvider.

final moneyRequestRepositoryProvider = Provider<MoneyRequestRepository>(
  (ref) => MoneyRequestRepositoryImpl(MoneyRequestApi(ref.watch(apiClientProvider))),
);

final requestMoneyProvider = Provider<RequestMoney>((ref) => RequestMoney(ref.watch(moneyRequestRepositoryProvider)));

final loadMoneyRequestsProvider = Provider<LoadMoneyRequests>(
  (ref) => LoadMoneyRequests(ref.watch(moneyRequestRepositoryProvider)),
);

final openMoneyRequestProvider = Provider<OpenMoneyRequest>(
  (ref) => OpenMoneyRequest(ref.watch(moneyRequestRepositoryProvider)),
);

final payMoneyRequestProvider = Provider<PayMoneyRequest>(
  (ref) => PayMoneyRequest(ref.watch(moneyRequestRepositoryProvider)),
);

final declineMoneyRequestProvider = Provider<DeclineMoneyRequest>(
  (ref) => DeclineMoneyRequest(ref.watch(moneyRequestRepositoryProvider)),
);

final cancelMoneyRequestProvider = Provider<CancelMoneyRequest>(
  (ref) => CancelMoneyRequest(ref.watch(moneyRequestRepositoryProvider)),
);
