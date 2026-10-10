import 'package:flutter/material.dart';

import '../../design_context.dart';
import '../../tokens/metrics.dart';

/// Looks like a search field and opens the real search when tapped ("Where to?").
class SearchBarButton extends StatelessWidget {
  const SearchBarButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const radius = BorderRadius.all(Radius.circular(Radii.input));

    return Semantics(
      button: true,
      child: Material(
        color: p.surface2,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: p.border),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: Sizes.inputHeight),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.x4),
              child: Row(
                children: [
                  Icon(Icons.search, color: p.textPrimary),
                  const SizedBox(width: Space.x3),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.typo.bodyStrong,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
