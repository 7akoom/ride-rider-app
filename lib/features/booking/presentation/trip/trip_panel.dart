import 'package:flutter/material.dart';

import '../../../../core/error/failure_messages.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../design/components/components.dart';
import '../../../../design/tokens/metrics.dart';
import '../../domain/entities/captain.dart';
import '../ride_summary_view.dart';
import 'trip_header.dart';
import 'trip_state.dart';

/// 18 to 20, under the map: where the trip stands, the captain and their car, the
/// ride, and cancelling it before it starts.
class TripPanel extends StatelessWidget {
  const TripPanel({super.key, required this.state, required this.onCancel});

  final TripState state;
  final VoidCallback onCancel;

  /// About the height of the captain's card.
  static const double _captainHeight = 112;

  Future<void> _confirmCancel(BuildContext context) async {
    final l10n = context.l10n;
    final yes = await confirmSheet(
      context,
      title: l10n.tripCancelTitle,
      message: l10n.tripCancelBody,
      confirmLabel: l10n.tripCancelYes,
      keepLabel: l10n.tripCancelNo,
    );

    if (yes) {
      onCancel();
    }
  }

  Widget _captain(AppLocalizations l10n, Captain? captain) {
    if (captain == null) {
      return const SkeletonView(child: SkeletonBox(height: _captainHeight, radius: Radii.card));
    }

    return DriverCard(
      name: captain.name.isEmpty ? l10n.tripCaptain : captain.name,
      car: captain.car,
      plate: captain.plate,
      rating: captain.rating,
      photoUrl: captain.photoUrl.isEmpty ? null : captain.photoUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final failure = state.failure;

    return MapPanel(
      children: [
        TripHeader(state: state),
        const SizedBox(height: Space.x4),
        _captain(l10n, state.captain),
        const SizedBox(height: Space.x3),
        RideSummaryView.ofRide(state.ride),
        if (failure != null) ...[
          const SizedBox(height: Space.x3),
          StatusBanner(tone: Tone.danger, message: failure.message(l10n)),
        ],
        if (state.canCancel) ...[
          const SizedBox(height: Space.x4),
          AppButton(
            label: l10n.tripCancel,
            icon: Icons.close,
            variant: AppButtonVariant.danger,
            loading: state.cancelling,
            onPressed: state.cancelling ? null : () => _confirmCancel(context),
          ),
        ],
      ],
    );
  }
}
