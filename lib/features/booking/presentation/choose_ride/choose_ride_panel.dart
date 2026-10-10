import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../design/components/components.dart';
import '../../../../design/tokens/metrics.dart';
import '../../domain/entities/fare_quote.dart';
import '../../domain/entities/trip_draft.dart';
import 'choose_ride_controller.dart';
import 'quote_list.dart';
import 'ride_texts.dart';

/// 11, under the map: notices, the ride types, payment and coupon, the request button.
class ChooseRidePanel extends ConsumerWidget {
  const ChooseRidePanel({
    super.key,
    required this.draft,
    required this.noRoad,
    required this.onPayment,
    required this.onPassenger,
    required this.onOrder,
  });

  final TripDraft draft;

  /// No road joins the points: the rider has to move one, so nothing can be requested.
  final bool noRoad;
  final VoidCallback onPayment;
  final VoidCallback onPassenger;
  final VoidCallback onOrder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(chooseRideControllerProvider(draft));
    final controller = ref.read(chooseRideControllerProvider(draft).notifier);
    final orderFailure = state.orderFailure;

    return MapPanel(
      children: [
        if (noRoad)
          _notice(StatusBanner(tone: Tone.danger, message: l10n.reviewNoRoad)),
        if (state.quotes?.surging ?? false)
          _notice(StatusBanner(tone: Tone.warning, message: l10n.chooseRideSurge)),
        if (orderFailure != null)
          _notice(StatusBanner(
            tone: Tone.danger,
            message: RideTexts.orderFailure(l10n, orderFailure),
          )),
        QuoteList(state: state, onSelect: controller.select, onRetry: controller.retry),
        const SizedBox(height: Space.x2),
        Row(
          children: [
            Expanded(
              child: PillButton(
                icon: RideTexts.paymentIcon(state.payment),
                label: RideTexts.payment(l10n, state.payment),
                onPressed: onPayment,
              ),
            ),
            const SizedBox(width: Space.x2),
            Expanded(
              child: PillButton(
                icon: Icons.local_offer_outlined,
                label: l10n.couponChip,
                marked: state.coupon == CouponResult.applied,
                onPressed: onPayment,
              ),
            ),
            const SizedBox(width: Space.x2),
            Expanded(
              child: PillButton(
                icon: Icons.person_add_alt_1_outlined,
                label: state.passenger?.name ?? l10n.passengerChip,
                marked: state.passenger != null,
                onPressed: onPassenger,
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.x4),
        AppButton(
          label: l10n.chooseRideOrder(
            RideTexts.vehicle(l10n, state.selectedClass ?? ''),
          ),
          loading: state.ordering,
          onPressed: state.canOrder && !noRoad ? onOrder : null,
        ),
      ],
    );
  }

  static Widget _notice(Widget banner) => Padding(
        padding: const EdgeInsetsDirectional.only(bottom: Space.x3),
        child: banner,
      );
}
