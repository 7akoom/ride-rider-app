import 'package:flutter/material.dart';

import '../../design_context.dart';
import '../../tokens/metrics.dart';

/// A round photo, or the person's initials when there is no photo or it fails to load.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = Sizes.avatar,
  });

  final String name;
  final String? imageUrl;
  final double size;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty);

    return parts.take(2).map((s) => s.characters.first).join();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final url = imageUrl;

    return ExcludeSemantics(
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: p.brandSoft,
        foregroundImage: url == null || url.isEmpty ? null : NetworkImage(url),
        onForegroundImageError: url == null || url.isEmpty ? null : (_, __) {},
        child: Text(_initials, style: context.typo.bodyStrong),
      ),
    );
  }
}
