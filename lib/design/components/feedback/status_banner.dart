import 'package:flutter/material.dart';

import '../../design_context.dart';
import '../../tokens/metrics.dart';
import '../layout/end_action_row.dart';
import 'tone.dart';

/// A tinted one-line message with an icon and an optional action: surge notice, dues,
/// location off, fees.
class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.tone,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final Tone tone;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsetsDirectional.all(Space.x3),
        decoration: BoxDecoration(
          color: tone.background(p),
          borderRadius: const BorderRadius.all(Radius.circular(Radii.input)),
        ),
        child: EndActionRow(
          actionLabel: actionLabel,
          onAction: onAction,
          child: Row(
            children: [
              Icon(tone.icon, size: Sizes.iconSmall, color: tone.foreground(p)),
              const SizedBox(width: Space.x2),
              Expanded(child: Text(message, style: context.typo.caption)),
            ],
          ),
        ),
      ),
    );
  }
}
