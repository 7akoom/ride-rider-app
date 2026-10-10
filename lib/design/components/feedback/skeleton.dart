import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../design_context.dart';
import '../../tokens/metrics.dart';
import 'skeleton_shimmer.dart';

/// One grey block of a loading placeholder, where a picture or a line of text will be.
/// It shines only inside a [SkeletonShimmer].
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.radius = Radii.input,
  });

  /// A round block, for avatars.
  const SkeletonBox.circle({super.key, required double size})
      : width = size,
        height = size,
        radius = size / 2;

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.palette.surface2,
        borderRadius: BorderRadius.all(Radius.circular(radius)),
      ),
    );
  }
}

/// The placeholder of a screen while it loads: its shape without its data, shining.
/// Screens build their own shape from [SkeletonBox]es; [SkeletonList] is the shape
/// of a plain list.
class SkeletonView extends StatelessWidget {
  const SkeletonView({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.loading,
      child: ExcludeSemantics(child: SkeletonShimmer(child: child)),
    );
  }
}

/// A list-shaped placeholder: [rows] rows of a square and two lines.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.rows = 4});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return SkeletonView(
      child: Column(
        children: [
          for (var i = 0; i < rows; i++)
            const Padding(
              padding: EdgeInsetsDirectional.only(bottom: Space.x4),
              child: Row(
                children: [
                  SkeletonBox(width: 40, height: 40),
                  SizedBox(width: Space.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(height: 14),
                        SizedBox(height: Space.x2),
                        SkeletonBox(width: 120, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A card-shaped placeholder: avatar, two lines and a wide block (driver, trip card).
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBox.circle(size: Sizes.avatar),
              SizedBox(width: Space.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 140, height: 14),
                    SizedBox(height: Space.x2),
                    SkeletonBox(width: 90, height: 12),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: Space.x4),
          SkeletonBox(height: 44),
        ],
      ),
    );
  }
}
