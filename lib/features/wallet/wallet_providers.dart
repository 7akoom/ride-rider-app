import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client_provider.dart';
import 'data/wallet_api.dart';
import 'data/wallet_repository_impl.dart';
import 'domain/repositories/wallet_repository.dart';
import 'domain/use_cases/follow_wallet.dart';

// The wallet feature's wiring: the one file that knows both the data classes and the
// domain interfaces. Tests override walletRepositoryProvider.

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => WalletRepositoryImpl(WalletApi(ref.watch(apiClientProvider))),
);

final loadWalletProvider = Provider<LoadWallet>((ref) => LoadWallet(ref.watch(walletRepositoryProvider)));

final loadStatementProvider = Provider<LoadStatement>(
  (ref) => LoadStatement(ref.watch(walletRepositoryProvider)),
);
