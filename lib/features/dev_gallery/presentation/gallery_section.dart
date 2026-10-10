import 'package:flutter/material.dart';

import '../../../design/components/components.dart';
import '../../../design/tokens/metrics.dart';

/// A titled group of examples in the gallery, with even spacing between them.
class GallerySection extends StatelessWidget {
  const GallerySection({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: Space.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: title),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: Space.x3),
            children[i],
          ],
        ],
      ),
    );
  }
}
