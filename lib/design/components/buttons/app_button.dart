import 'package:flutter/material.dart';

import '../../design_context.dart';
import '../../theme/button_themes.dart';
import '../../tokens/metrics.dart';
import '../../tokens/palette.dart';
import 'loading_dots.dart';

enum AppButtonVariant { primary, secondary, ink, danger, text }

/// The app's button. Full width by default (one primary action per screen); [expand]
/// false sizes it to its label. While [loading] it shows three hopping dots instead of
/// its label and ignores taps, without greying out.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.typo;

    var style = switch (variant) {
      AppButtonVariant.primary => primaryButtonStyle(p, t),
      AppButtonVariant.secondary => secondaryButtonStyle(p, t),
      AppButtonVariant.ink => inkButtonStyle(p, t),
      AppButtonVariant.danger => dangerButtonStyle(p, t),
      AppButtonVariant.text => textButtonStyle(p, t),
    };

    if (!expand && variant != AppButtonVariant.text) {
      style = style.copyWith(
        minimumSize: const WidgetStatePropertyAll(
          Size(Sizes.touchTarget, Sizes.buttonHeight),
        ),
      );
    }

    return IgnorePointer(
      ignoring: loading,
      child: TextButton(
        style: style,
        onPressed: onPressed,
        child: loading ? LoadingDots(color: _foreground(p)) : _content(),
      ),
    );
  }

  Widget _content() {
    final text = Text(label, maxLines: 1, overflow: TextOverflow.ellipsis);

    if (icon == null) {
      return text;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: Sizes.iconSmall),
        const SizedBox(width: Space.x2),
        Flexible(child: text),
      ],
    );
  }

  Color _foreground(Palette p) => switch (variant) {
        AppButtonVariant.primary => p.onBrand,
        AppButtonVariant.ink => p.onInk,
        AppButtonVariant.danger => p.danger,
        AppButtonVariant.secondary => p.textPrimary,
        AppButtonVariant.text => p.brandStrong,
      };
}
