import 'package:flutter/material.dart';

import '../../design_context.dart';
import '../../responsive/content_width.dart';
import '../../tokens/metrics.dart';

/// Every screen's frame: background, safe areas, the readable content width and the
/// side gutters, with an optional action area pinned to the bottom.
///
/// Screens that draw edge to edge (the map) set [padded] to false.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.topBar,
    this.bottomAction,
    this.bottomNavigation,
    this.padded = true,
  });

  final Widget body;
  final PreferredSizeWidget? topBar;

  /// Usually the screen's primary button.
  final Widget? bottomAction;
  final Widget? bottomNavigation;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    const gutter = EdgeInsetsDirectional.symmetric(horizontal: Space.gutter);

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: topBar,
      bottomNavigationBar: bottomNavigation,
      body: SafeArea(
        top: topBar == null,
        bottom: bottomNavigation == null,
        child: Column(
          children: [
            Expanded(
              child: padded
                  ? ContentWidth(child: Padding(padding: gutter, child: body))
                  : body,
            ),
            if (bottomAction != null)
              ContentWidth(
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    Space.gutter,
                    Space.x3,
                    Space.gutter,
                    Space.x4,
                  ),
                  child: bottomAction,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
