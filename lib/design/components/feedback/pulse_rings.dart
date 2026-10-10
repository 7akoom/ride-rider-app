import 'package:flutter/material.dart';

import '../../design_context.dart';
import '../trip/route_markers.dart';

/// Rings spreading from the pickup marker while the platform looks for a captain.
/// Still rings when the phone asks for less motion.
class PulseRings extends StatefulWidget {
  const PulseRings({super.key, this.size = 200});

  final double size;

  @override
  State<PulseRings> createState() => _PulseRingsState();
}

class _PulseRingsState extends State<PulseRings> with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  static const int _rings = 3;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (MediaQuery.disableAnimationsOf(context)) {
      _wave.value = 0.5;
      _wave.stop();
    } else if (!_wave.isAnimating) {
      _wave.repeat();
    }
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.palette.brand;

    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _wave,
        builder: (context, _) => Stack(
          alignment: Alignment.center,
          children: [
            for (var i = 0; i < _rings; i++) _ring(brand, (_wave.value + i / _rings) % 1),
            const RouteMarker(kind: RoutePointKind.pickup),
          ],
        ),
      ),
    );
  }

  /// One ring at [progress] (0 small and strong, 1 wide and gone).
  Widget _ring(Color color, double progress) {
    final size = RouteMarker.size + (widget.size - RouteMarker.size) * progress;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.35 * (1 - progress)),
      ),
    );
  }
}
