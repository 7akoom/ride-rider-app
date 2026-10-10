import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client_provider.dart';
import 'rider_account_api.dart';
import 'rider_account_repository.dart';
import 'rider_account_repository_impl.dart';

/// The signed-in rider's profile, for every feature. Tests override it with a fake.
final riderAccountRepositoryProvider = Provider<RiderAccountRepository>(
  (ref) => RiderAccountRepositoryImpl(RiderAccountApi(ref.watch(apiClientProvider))),
);
