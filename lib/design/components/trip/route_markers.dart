import 'package:flutter/material.dart';

import '../../design_context.dart';

enum RoutePointKind { pickup, stop, destination }

/// The marker of a route point, the same on lists and on the map: pickup is an ink
/// circle with a person, a stop a hollow circle, the destination a brand square with a
/// flag.
class RouteMarker extends StatelessWidget {
  const RouteMarker({super.key, required this.kind});

  final RoutePointKind kind;

  static const double size = 24;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return SizedBox.square(
      dimension: size,
      child: switch (kind) {
        RoutePointKind.pickup => DecoratedBox(
            decoration: BoxDecoration(color: p.ink, shape: BoxShape.circle),
            child: Icon(Icons.person, size: 14, color: p.onInk),
          ),
        RoutePointKind.stop => DecoratedBox(
            decoration: BoxDecoration(
              color: p.surface,
              shape: BoxShape.circle,
              border: Border.all(color: p.textSecondary, width: 2),
            ),
          ),
        RoutePointKind.destination => DecoratedBox(
            decoration: BoxDecoration(
              color: p.brand,
              borderRadius: const BorderRadius.all(Radius.circular(6)),
            ),
            child: Icon(Icons.flag, size: 14, color: p.onBrand),
          ),
      },
    );
  }
}
