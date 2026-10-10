import 'package:flutter/material.dart';

import '../../design_context.dart';

/// Sweeps one band of light across every [SkeletonBox] below it, together, in the
/// reading direction (from the right in Arabic and Kurdish). Wrap a whole screen's
/// placeholder in one of these, not each box. When the device asks for less motion
/// the placeholder stays still.
class SkeletonShimmer extends StatefulWidget {
  const SkeletonShimmer({super.key, required this.child});

  final Widget child;

  static const Duration period = Duration(milliseconds: 1400);

  @override
  State<SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<SkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: SkeletonShimmer.period,
  );

  bool get _still => MediaQuery.disableAnimationsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_still) {
      _sweep.stop();
    } else if (!_sweep.isAnimating) {
      _sweep.repeat();
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_still) {
      return widget.child;
    }

    final p = context.palette;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final base = p.surface2;
    final light = dark ? p.border : p.surface;

    return AnimatedBuilder(
      animation: _sweep,
      child: widget.child,
      builder: (context, child) {
        final progress = rtl ? 1 - _sweep.value : _sweep.value;

        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            colors: [base, light, base],
            stops: const [0.35, 0.5, 0.65],
            transform: _Slide(progress * 2 - 1),
          ).createShader(bounds),
          child: child,
        );
      },
    );
  }
}

/// Moves the gradient sideways by [offset] widths (-1: off the left edge, 1: off the
/// right edge).
class _Slide extends GradientTransform {
  const _Slide(this.offset);

  final double offset;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * offset, 0, 0);
}
