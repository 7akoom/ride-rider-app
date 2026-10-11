import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure_messages.dart';
import '../../../../core/error/result.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../design/components/components.dart';
import '../../../../design/design_context.dart';
import '../../../../design/tokens/metrics.dart';
import '../../booking_providers.dart';
import '../../domain/entities/scheduled_ride.dart';
import '../../domain/use_cases/schedule_window.dart';
import '../ride_summary_view.dart';
import 'booked_time_card.dart';

/// Shows a booking just made. Going back from it leads home.
Future<void> openScheduled(BuildContext context, ScheduledRide booking, {int? estimate}) =>
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => ScheduledScreen(booking: booking, estimate: estimate)),
      (route) => route.isFirst,
    );

/// 17: the ride is booked; when the search for a captain starts, and cancelling it.
class ScheduledScreen extends ConsumerStatefulWidget {
  const ScheduledScreen({super.key, required this.booking, this.estimate});

  final ScheduledRide booking;

  /// The chosen ride type's price when it was booked; the real one is set later.
  final int? estimate;

  @override
  ConsumerState<ScheduledScreen> createState() => _ScheduledScreenState();
}

class _ScheduledScreenState extends ConsumerState<ScheduledScreen> {
  bool _cancelling = false;

  void _home() => Navigator.of(context).popUntil((route) => route.isFirst);

  Future<void> _cancel() async {
    final l10n = context.l10n;
    final yes = await confirmSheet(
      context,
      title: l10n.bookingCancelTitle,
      message: l10n.bookingCancelBody,
      confirmLabel: l10n.searchingCancelYes,
      keepLabel: l10n.bookingCancelNo,
    );

    if (!yes || !mounted) {
      return;
    }

    setState(() => _cancelling = true);
    final result = await ref.read(cancelBookingProvider).call(widget.booking.id);

    if (!mounted) {
      return;
    }

    setState(() => _cancelling = false);

    switch (result) {
      case Ok():
        showAppToast(context, l10n.bookingCancelled, tone: Tone.info);
        _home();
      case Err(:final failure):
        showAppToast(context, failure.message(l10n), tone: Tone.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final booking = widget.booking;
    const lead = ScheduleWindow();

    return AppScaffold(
      topBar: AppTopBar(title: l10n.bookedBarTitle),
      bottomAction: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton(label: l10n.bookedDone, onPressed: _cancelling ? null : _home),
          const SizedBox(height: Space.x2),
          AppButton(
            label: l10n.bookingCancel,
            variant: AppButtonVariant.text,
            loading: _cancelling,
            onPressed: _cancelling ? null : _cancel,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.symmetric(vertical: Space.x4),
        children: [
          Center(
            child: Container(
              width: Sizes.hero,
              height: Sizes.hero,
              decoration: BoxDecoration(color: p.successSoft, shape: BoxShape.circle),
              child: Icon(Icons.check_circle, size: Sizes.heroIcon, color: p.success),
            ),
          ),
          const SizedBox(height: Space.x4),
          Text(l10n.bookedTitle, style: context.typo.h2, textAlign: TextAlign.center),
          const SizedBox(height: Space.x1),
          Text(
            l10n.bookedExplain(lead.dispatchLead.inMinutes),
            style: context.typo.caption.copyWith(color: p.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.x5),
          BookedTimeCard(at: booking.at),
          const SizedBox(height: Space.x3),
          RideSummaryView(
            pickup: booking.pickupAddress,
            dropoff: booking.dropoffAddress,
            stops: [for (final stop in booking.stops) stop.address],
            vehicleClass: booking.vehicleClass,
            payment: booking.payment,
            fare: widget.estimate,
          ),
          if (widget.estimate != null) ...[
            const SizedBox(height: Space.x3),
            StatusBanner(tone: Tone.info, message: l10n.bookedEstimate),
          ],
        ],
      ),
    );
  }
}
