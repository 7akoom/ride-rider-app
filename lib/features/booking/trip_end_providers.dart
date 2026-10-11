import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client_provider.dart';
import 'data/trip_end_api.dart';
import 'data/trip_end_repository_impl.dart';
import 'domain/repositories/trip_end_repository.dart';
import 'domain/use_cases/finish_trip.dart';

// The end of a trip's wiring (summary, rating, tip, receipt), beside booking_providers.
// Tests override tripEndRepositoryProvider.

final tripEndRepositoryProvider = Provider<TripEndRepository>(
  (ref) => TripEndRepositoryImpl(TripEndApi(ref.watch(apiClientProvider))),
);

final loadPaymentProvider = Provider<LoadPayment>(
  (ref) => LoadPayment(ref.watch(tripEndRepositoryProvider)),
);

final rateCaptainProvider = Provider<RateCaptain>(
  (ref) => RateCaptain(ref.watch(tripEndRepositoryProvider)),
);

final tipCaptainProvider = Provider<TipCaptain>(
  (ref) => TipCaptain(ref.watch(tripEndRepositoryProvider)),
);
