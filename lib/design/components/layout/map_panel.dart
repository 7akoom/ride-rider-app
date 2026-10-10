import 'package:flutter/material.dart';

import '../../design_context.dart';
import '../../tokens/metrics.dart';
import '../../tokens/shadows.dart';

/// The raised sheet under a map (home, picking a point, choosing a ride): rounded top,
/// shadow, gutters. Its children fill the width.
class MapPanel extends StatelessWidget {
  const MapPanel({super.key, required this.children});

  final List<Widget> children;

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
        children: children,
      ),
    );
  }
}
