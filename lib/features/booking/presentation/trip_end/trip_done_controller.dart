import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../booking_providers.dart';
import '../../domain/entities/captain.dart';
import '../../domain/entities/ride.dart';
import '../../domain/entities/trip_payment.dart';
import '../../trip_end_providers.dart';

/// How often the settlement is asked for while it is not there. Tests shorten it.
final paymentCheckIntervalProvider = Provider<Duration>((ref) => const Duration(seconds: 1));

final tripDoneControllerProvider =
    NotifierProvider.autoDispose.family<TripDoneController, TripDoneState, Ride>(TripDoneController.new);

/// A finished trip: how it was paid (once settled) and who drove it.
final class TripDoneState {
  const TripDoneState({required this.ride, this.payment, this.captain, this.late = false});

  final Ride ride;
  final TripPayment? payment;
  final Captain? captain;

  /// The settlement did not come in time: the fare shows in the activity later.
  final bool late;

  TripDoneState copyWith({TripPayment? payment, Captain? captain, bool? late}) => TripDoneState(
        ride: ride,
        payment: payment ?? this.payment,
        captain: captain ?? this.captain,
        late: late ?? this.late,
      );
}

/// The platform settles a trip a few seconds after it ends: asked for each second,
/// for half a minute at most.
class TripDoneController extends AutoDisposeFamilyNotifier<TripDoneState, Ride> {
  static const int maxChecks = 30;

  Timer? _poll;
  int _checks = 0;
  bool _checking = false;
  bool _closed = false;

  @override
  TripDoneState build(Ride arg) {
    ref.onDispose(() {
      _closed = true;
      _poll?.cancel();
    });
    _poll = Timer.periodic(ref.read(paymentCheckIntervalProvider), (_) => unawaited(_check()));
    unawaited(Future.microtask(_start));

    return TripDoneState(ride: arg);
  }

  Future<void> _start() async {
    unawaited(_check());
    final captain = await ref.read(loadCaptainProvider).call(arg.id);

    if (!_closed && captain is Ok<Captain>) {
      state = state.copyWith(captain: captain.value);
    }
  }

  Future<void> _check() async {
    if (_checking || _closed || state.payment != null) {
      return;
    }

    _checking = true;
    _checks++;
    final result = await ref.read(loadPaymentProvider).call(arg.id);
    _checking = false;

    if (_closed) {
      return;
    }

    if (result case Ok(value: final payment?)) {
      _poll?.cancel();
      state = state.copyWith(payment: payment);
    } else if (_checks >= maxChecks) {
      _poll?.cancel();
      state = state.copyWith(late: true);
    }
  }
}
