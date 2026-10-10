import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../design_context.dart';
import '../../responsive/content_width.dart';
import '../../tokens/metrics.dart';
import '../buttons/app_icon_button.dart';

/// Opens a modal bottom sheet with the app's look: drag handle, rounded top, the
/// readable width, side gutters, and room for the keyboard.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
      child: ContentWidth(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            Space.gutter,
            0,
            Space.gutter,
            Space.x4,
          ),
          child: builder(sheetContext),
        ),
      ),
    ),
  );
}

/// A sheet's title row, with an optional close button at the end.
class SheetTitle extends StatelessWidget {
  const SheetTitle({super.key, required this.title, this.onClose});

  final String title;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: Space.x4),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: context.typo.h2),
            ),
          ),
          if (onClose != null)
            AppIconButton(
              icon: Icons.close,
              semanticLabel: context.l10n.actionClose,
              onPressed: onClose,
            ),
        ],
      ),
    );
  }
}
