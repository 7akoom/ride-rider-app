import 'package:flutter/material.dart';

import '../../design_context.dart';
import '../../tokens/metrics.dart';
import '../../tokens/shadows.dart';

/// The raised sheet under a map (home, picking a point, choosing a ride): rounded top,
/// shadow, gutters. Its children fill the width. With [handle] it shows the grip of a
/// sheet the rider drags up and down.
class MapPanel extends StatelessWidget {
  const MapPanel({super.key, required this.children, this.handle = false});

  final List<Widget> children;
  final bool handle;

  /// The grip's size.
  static const Size _grip = Size(40, 4);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.sheet)),
        boxShadow: Shadows.floating,
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(
        Space.gutter,
        Space.x5,
        Space.gutter,
        Space.x4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (handle) ...[
            Center(
              child: Container(
                width: _grip.width,
                height: _grip.height,
                decoration: BoxDecoration(
                  color: context.palette.border,
                  borderRadius: const BorderRadius.all(Radius.circular(Radii.pill)),
                ),
              ),
            ),
            const SizedBox(height: Space.x4),
          ],
          ...children,
        ],
      ),
    );
  }
}
