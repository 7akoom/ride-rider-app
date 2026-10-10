import 'package:flutter/material.dart';

import '../../design_context.dart';
import '../../tokens/metrics.dart';
import 'route_markers.dart';

/// One point of a route: where it is and what kind of point it is.
class RoutePoint {
  const RoutePoint({
    required this.kind,
    required this.label,
    required this.title,
    this.subtitle,
  });

  final RoutePointKind kind;

  /// "Pickup", "Stop 1", "Destination" (translated by the caller).
  final String label;
  final String title;
  final String? subtitle;
}

/// Pickup, stops and destination joined by a line along the start edge.
class RouteSummary extends StatelessWidget {
  const RouteSummary({super.key, required this.points});

  final List<RoutePoint> points;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < points.length; i++)
          _PointRow(point: points[i], isLast: i == points.length - 1),
      ],
    );
  }
}

class _PointRow extends StatelessWidget {
  const _PointRow({required this.point, required this.isLast});

  final RoutePoint point;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.typo;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: RouteMarker.size,
            child: Column(
              children: [
                RouteMarker(kind: point.kind),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: p.border)),
              ],
            ),
          ),
          const SizedBox(width: Space.x3),
          Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(bottom: isLast ? 0 : Space.x4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(point.label, style: t.micro.copyWith(color: p.textTertiary)),
                  // A long address keeps to two lines; the summary stays compact.
                  Text(
                    point.title,
                    style: t.bodyStrong,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (point.subtitle != null)
                    Text(
                      point.subtitle!,
                      style: t.caption.copyWith(color: p.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
