import 'package:flutter/material.dart';

import '../../../../core/error/failure_messages.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../design/components/components.dart';
import '../../../../design/design_context.dart';
import '../../../../design/tokens/metrics.dart';
import '../ride_summary_view.dart';
import 'searching_state.dart';

/// 16: the search ran out. Try the same ride again, or choose another type.
class NoCaptainPanel extends StatelessWidget {
  const NoCaptainPanel({
    super.key,
    required this.state,
    required this.onRetry,
    required this.onChange,
  });

  final SearchingState state;
  final VoidCallback onRetry;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final failure = state.failure;
    final retrying = state.phase == SearchPhase.retrying;

    return MapPanel(
      children: [
        Center(
          child: Container(
            width: Sizes.hero,
            height: Sizes.hero,
            decoration: BoxDecoration(color: p.surface2, shape: BoxShape.circle),
            child: Icon(Icons.no_crash_outlined, size: Sizes.heroIcon, color: p.textSecondary),
          ),
        ),
        const SizedBox(height: Space.x4),
        Text(l10n.noCaptainTitle, style: context.typo.h2, textAlign: TextAlign.center),
        const SizedBox(height: Space.x1),
        Text(
          l10n.noCaptainSubtitle,
          style: context.typo.caption.copyWith(color: p.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Space.x4),
        RideSummaryView.ofRide(state.ride),
        if (failure != null) ...[
          const SizedBox(height: Space.x3),
          StatusBanner(tone: Tone.danger, message: failure.message(l10n)),
        ],
        const SizedBox(height: Space.x4),
        AppButton(
          label: l10n.actionRetry,
          icon: Icons.refresh,
          loading: retrying,
          onPressed: retrying ? null : onRetry,
        ),
        const SizedBox(height: Space.x2),
        AppButton(
          label: l10n.noCaptainChange,
          icon: Icons.local_taxi_outlined,
          variant: AppButtonVariant.secondary,
          onPressed: retrying ? null : onChange,
        ),
      ],
    );
  }
}
