import 'package:flutter/material.dart';

import '../../../../core/format/bidi.dart';
import '../../../../core/format/time_format.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../design/components/components.dart';
import '../../../../design/design_context.dart';
import '../../../../design/tokens/metrics.dart';
import '../../domain/entities/captain.dart';
import '../../domain/entities/ride.dart';
import '../../domain/entities/trip_payment.dart';
import '../../domain/use_cases/retry_ride.dart';
import '../choose_ride/choose_ride_screen.dart';
import '../ride_summary_view.dart';
import 'fare_view.dart';

Future<void> openReceipt(BuildContext context, Ride ride, TripPayment payment, Captain? captain) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReceiptScreen(ride: ride, payment: payment, captain: captain),
      ),
    );

/// 27: the receipt of a finished trip, and taking the same trip again.
class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key, required this.ride, required this.payment, this.captain});

  final Ride ride;
  final TripPayment payment;
  final Captain? captain;

  /// The trip's number as people read it: the start of its id.
  String get number {
    final id = ride.id.replaceAll('-', '').toUpperCase();

    return id.length > 8 ? id.substring(0, 8) : id;
  }

  void _again(BuildContext context) => Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => ChooseRideScreen(draft: draftOf(ride))),
        (route) => route.isFirst,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final t = context.typo;
    final ended = (ride.completedAt ?? DateTime.now()).toLocal();
    final started = ride.startedAt;
    final minutes = started == null ? null : ride.completedAt?.difference(started).inMinutes;
    final captain = this.captain;

    return AppScaffold(
      topBar: AppTopBar(title: l10n.receiptBarTitle),
      body: ListView(
        padding: const EdgeInsetsDirectional.symmetric(vertical: Space.x4),
        children: [
          Text(l10n.receiptNumber(isolateLtr(number)), style: t.h3),
          const SizedBox(height: Space.x1),
          Text(
            l10n.receiptWhen(formatDate(l10n, ended), formatClock(l10n, ended)),
            style: t.caption.copyWith(color: p.textSecondary),
          ),
          if (minutes != null)
            Text(
              l10n.receiptDuration(l10n.etaMinutes(minutes < 1 ? 1 : minutes)),
              style: t.caption.copyWith(color: p.textSecondary),
            ),
          const SizedBox(height: Space.x4),
          RideSummaryView.ofRide(ride),
          if (captain != null) ...[
            const SizedBox(height: Space.x3),
            DriverCard(
              name: captain.name.isEmpty ? l10n.tripCaptain : captain.name,
              car: captain.car,
              plate: captain.plate,
              rating: captain.rating,
              photoUrl: captain.photoUrl.isEmpty ? null : captain.photoUrl,
            ),
          ],
          const SizedBox(height: Space.x3),
          FareView(payment: payment),
          const SizedBox(height: Space.x4),
          AppListRow(
            icon: Icons.replay,
            title: l10n.receiptAgain,
            subtitle: ride.dropoffAddress.isEmpty ? null : ride.dropoffAddress,
            onTap: () => _again(context),
          ),
        ],
      ),
    );
  }
}
