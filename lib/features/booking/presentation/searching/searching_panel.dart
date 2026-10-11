import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/error/failure_messages.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../design/components/components.dart';
import '../../../../design/design_context.dart';
import '../../../../design/tokens/metrics.dart';
import '../ride_summary_view.dart';
import 'searching_state.dart';

/// 15, under the map: looking for a captain, the ride, and cancelling it.
class SearchingPanel extends StatelessWidget {
  const SearchingPanel({super.key, required this.state, required this.onCancel});

  final SearchingState state;
  final VoidCallback onCancel;

  /// How long the platform looks before it gives up (dispatch's search timeout).
  static const Duration searchTime = Duration(minutes: 2);

  Future<void> _confirmCancel(BuildContext context) async {
    final l10n = context.l10n;
    final yes = await confirmSheet(
      context,
      title: l10n.searchingCancelTitle,
      message: l10n.searchingCancelBody,
      confirmLabel: l10n.searchingCancelYes,
      keepLabel: l10n.searchingCancelNo,
    );

    if (yes) {
      onCancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final failure = state.failure;
    final since = state.ride.requestedAt ?? DateTime.now();

    return MapPanel(
      children: [
        Text(l10n.searchingTitle, style: context.typo.h2, textAlign: TextAlign.center),
        const SizedBox(height: Space.x1),
        Text(
          l10n.searchingSubtitle,
          style: context.typo.caption.copyWith(color: p.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Space.x3),
        CountdownBuilder(
          until: since.add(searchTime),
          builder: (context, remaining) => LinearProgressIndicator(
            value: math.min(0.95, math.max(0.05, 1 - remaining.inSeconds / searchTime.inSeconds)),
            color: p.brand,
            backgroundColor: p.surface2,
            borderRadius: const BorderRadius.all(Radius.circular(Radii.pill)),
          ),
        ),
        const SizedBox(height: Space.x4),
        RideSummaryView.ofRide(state.ride),
        const SizedBox(height: Space.x3),
        StatusBanner(tone: Tone.info, message: l10n.searchingNotice),
        if (failure != null) ...[
          const SizedBox(height: Space.x2),
          StatusBanner(tone: Tone.danger, message: failure.message(l10n)),
        ],
        const SizedBox(height: Space.x4),
        AppButton(
          label: l10n.searchingCancel,
          icon: Icons.close,
          variant: AppButtonVariant.danger,
          loading: state.phase == SearchPhase.cancelling,
          onPressed: state.phase == SearchPhase.waiting ? () => _confirmCancel(context) : null,
        ),
      ],
    );
  }
}
