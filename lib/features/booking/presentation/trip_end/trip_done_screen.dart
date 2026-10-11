import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format/money_format.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../design/components/components.dart';
import '../../../../design/design_context.dart';
import '../../../../design/tokens/metrics.dart';
import '../../domain/entities/captain.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/ride.dart';
import '../ride_summary_view.dart';
import 'fare_view.dart';
import 'rate_screen.dart';
import 'receipt_screen.dart';
import 'trip_done_controller.dart';

/// The trip ended: its summary in place of the trip screen. Back leads home.
Future<void> openTripDone(BuildContext context, Ride ride) => Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => TripDoneScreen(ride: ride)),
    );

/// 24: arrived safely, what it cost and how to pay, the captain; then rating and receipt.
class TripDoneScreen extends ConsumerWidget {
  const TripDoneScreen({super.key, required this.ride});

  final Ride ride;

  static const double _amountHeight = 44;

  Widget _amount(BuildContext context, TripDoneState state) {
    final l10n = context.l10n;
    final t = context.typo;
    final payment = state.payment;

    if (payment == null) {
      return state.late
          ? Text(l10n.tripDoneFareLater, style: t.caption, textAlign: TextAlign.center)
          : const SkeletonView(child: SkeletonBox(height: _amountHeight));
    }

    return Column(
      children: [
        MoneyText(payment.total, style: t.display),
        const SizedBox(height: Space.x1),
        Text(
          payment.method == PaymentMethod.cash && payment.cash > 0
              ? l10n.tripDonePayCash(formatMoney(l10n, payment.cash))
              : l10n.tripDonePaidWallet,
          style: t.caption.copyWith(color: context.palette.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  static Widget _captain(AppLocalizations l10n, Captain captain) => DriverCard(
        name: captain.name.isEmpty ? l10n.tripCaptain : captain.name,
        car: captain.car,
        plate: captain.plate,
        rating: captain.rating,
        photoUrl: captain.photoUrl.isEmpty ? null : captain.photoUrl,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final p = context.palette;
    final state = ref.watch(tripDoneControllerProvider(ride));
    final payment = state.payment;
    final captain = state.captain;

    return AppScaffold(
      topBar: AppTopBar(title: l10n.tripDoneBarTitle),
      bottomAction: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppButton(
            label: l10n.tripDoneRate,
            icon: Icons.star_outline_rounded,
            onPressed: () => openRate(context, ride, captain),
          ),
          if (payment != null) ...[
            const SizedBox(height: Space.x2),
            AppButton(
              label: l10n.tripDoneReceipt,
              variant: AppButtonVariant.text,
              onPressed: () => openReceipt(context, ride, payment, captain),
            ),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.symmetric(vertical: Space.x4),
        children: [
          Icon(Icons.check_circle_outline, size: Sizes.heroIcon, color: p.success),
          const SizedBox(height: Space.x2),
          Text(l10n.tripDoneTitle, style: context.typo.h2, textAlign: TextAlign.center),
          const SizedBox(height: Space.x3),
          _amount(context, state),
          const SizedBox(height: Space.x5),
          if (captain != null) ...[_captain(l10n, captain), const SizedBox(height: Space.x3)],
          RideSummaryView.ofRide(ride),
          if (payment != null) ...[const SizedBox(height: Space.x3), FareView(payment: payment)],
        ],
      ),
    );
  }
}
