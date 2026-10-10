import 'package:flutter/widgets.dart';

import '../tokens/metrics.dart';

/// Keeps a screen's content at a readable width: full width on phones, a centred
/// column of at most [maxWidth] on tablets and wide screens.
class ContentWidth extends StatelessWidget {
  const ContentWidth({
    super.key,
    required this.child,
    this.maxWidth = Sizes.maxContentWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
