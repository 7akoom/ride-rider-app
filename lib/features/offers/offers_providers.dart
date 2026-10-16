import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/result.dart';
import '../../core/network/api_client_provider.dart';
import 'data/offers_api.dart';
import 'data/offers_repository_impl.dart';
import 'domain/entities/offer.dart';
import 'domain/repositories/offers_repository.dart';
import 'domain/use_cases/offers.dart';

// The offers feature's wiring. Tests override offersRepositoryProvider.

final offersRepositoryProvider = Provider<OffersRepository>(
  (ref) => OffersRepositoryImpl(OffersApi(ref.watch(apiClientProvider))),
);

final loadOffersProvider = Provider<LoadOffers>((ref) => LoadOffers(ref.watch(offersRepositoryProvider)));

final checkCodeProvider = Provider<CheckCode>((ref) => CheckCode(ref.watch(offersRepositoryProvider)));

final keepCodeProvider = Provider<KeepCode>((ref) => KeepCode(ref.watch(offersRepositoryProvider)));

/// The home's offers; a failure is a value (the section then stays hidden).
final offersProvider = FutureProvider.autoDispose<Result<RiderOffers>>(
  (ref) => ref.watch(loadOffersProvider).call(),
);

/// The code kept for the next ride; null for none.
final keptCodeProvider = FutureProvider.autoDispose<String?>((ref) => ref.watch(keepCodeProvider).kept());
