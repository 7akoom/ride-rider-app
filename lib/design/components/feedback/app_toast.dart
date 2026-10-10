import 'package:flutter/material.dart';

import '../../design_context.dart';
import '../../tokens/metrics.dart';
import 'tone.dart';

/// A short message at the bottom of the screen ("Address saved", or a failure's
/// translated message). Replaces any toast already showing.
void showAppToast(
  BuildContext context,
  String message, {
  Tone tone = Tone.success,
}) {
  final p = context.palette;
  final messenger = ScaffoldMessenger.of(context);

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(tone.icon, size: Sizes.iconSmall, color: tone.foreground(p)),
            const SizedBox(width: Space.x2),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}
