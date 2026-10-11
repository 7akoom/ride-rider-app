import 'package:flutter/material.dart';

import '../../design_context.dart';
import '../../tokens/metrics.dart';
import '../buttons/app_button.dart';
import 'app_sheet.dart';

/// Asks before something that cannot be taken back (cancelling a request or a
/// booking). True only when the rider confirmed.
Future<bool> confirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String keepLabel,
}) async {
  final confirmed = await showAppSheet<bool>(
    context: context,
    builder: (sheet) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(title: title),
        Text(message, style: sheet.typo.body),
        const SizedBox(height: Space.x5),
        AppButton(
          label: confirmLabel,
          variant: AppButtonVariant.danger,
          onPressed: () => Navigator.of(sheet).pop(true),
        ),
        const SizedBox(height: Space.x2),
        AppButton(
          label: keepLabel,
          variant: AppButtonVariant.text,
          onPressed: () => Navigator.of(sheet).pop(false),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}
