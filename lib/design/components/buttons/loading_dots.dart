import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../tokens/metrics.dart';

/// Three dots that hop one after another: a button waiting for its answer. When the
/// device asks for less motion they stay still.
class LoadingDots extends StatefulWidget {
  const LoadingDots({super.key, required this.color});

  final Color color;

  static const double dotSize = 7;
  static const double hop = 4;
  static const Duration period = Duration(milliseconds: 1000);

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _beat = AnimationController(
    vsync: this,
    duration: LoadingDots.period,
  );

  bool get _still => MediaQuery.disableAnimationsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_still) {
      _beat.stop();
    } else if (!_beat.isAnimating) {
      _beat.repeat();
    }
  }

  @override
  void dispose() {
    _beat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.loading,
      child: SizedBox(
        height: LoadingDots.dotSize + LoadingDots.hop,
        child: AnimatedBuilder(
          animation: _beat,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: Space.x1),
                _Dot(color: widget.color, lift: _still ? 0 : _lift(i)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 0 (resting) to 1 (top of the hop) for dot [index]; each dot starts a little
  /// after the one before it, then rests for the second half of the beat.
  double _lift(int index) {
    final phase = (_beat.value - index * 0.15) % 1;

    return phase < 0.5 ? math.sin(phase * 2 * math.pi) : 0;
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.lift});

  final Color color;
  final double lift;

  @override
  Widget build(BuildContext context) {
    final up = lift.clamp(0.0, 1.0);

    return Transform.translate(
      offset: Offset(0, -LoadingDots.hop * up),
      child: Opacity(
        opacity: 0.45 + 0.55 * up,
        child: Container(
          width: LoadingDots.dotSize,
          height: LoadingDots.dotSize,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
