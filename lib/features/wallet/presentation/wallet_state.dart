import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../domain/entities/top_up.dart';
import '../domain/entities/wallet_movement.dart';
import '../domain/entities/wallet_overview.dart';
import '../wallet_providers.dart';

/// The wallet screen's data. A failure is a value, so the screen shows it in words.
final walletProvider = FutureProvider.autoDispose<Result<(WalletOverview, List<WalletMovement>)>>(
  (ref) => ref.watch(loadWalletProvider).call(),
);

/// The balance alone, for the home screen; null while unknown or unavailable.
final walletBalanceProvider = Provider.autoDispose<int?>((ref) {
  return switch (ref.watch(walletProvider).valueOrNull) {
    Ok(value: (final overview, _)) => overview.balance,
    _ => null,
  };
});

/// What a top-up may be here; the wallet offers it only when ZainCash is set up.
final topUpOptionsProvider = FutureProvider.autoDispose<Result<TopUpOptions>>(
  (ref) => ref.watch(loadTopUpOptionsProvider).call(),
);
