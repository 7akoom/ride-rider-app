import 'package:flutter/material.dart';

import '../../design_context.dart';
import '../../responsive/content_width.dart';
import '../../tokens/metrics.dart';

/// Every screen's frame: background, safe areas, the readable content width and the
/// side gutters, with an optional action area pinned to the bottom.
///
/// Screens that draw edge to edge (the map) set [padded] to false; their body then
/// gets the full width, whatever its own size (a map under a small pin would otherwise
/// shrink to the pin's width), and keeps its height when the keyboard opens (over
/// another screen too): a map must never change size (see MapLayout).
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.topBar,
    this.bottomAction,
    this.bottomNavigation,
    this.padded = true,
    this.background,
  });

  final Widget body;
  final PreferredSizeWidget? topBar;

  /// Usually the screen's primary button.
  final Widget? bottomAction;
  final Widget? bottomNavigation;
  final bool padded;

  /// Replaces the page background (the start screen uses the dark ink).
  final Color? background;

  @override
  Widget build(BuildContext context) {
    const gutter = EdgeInsetsDirectional.symmetric(horizontal: Space.gutter);

    return Scaffold(
      backgroundColor: background ?? context.palette.background,
      resizeToAvoidBottomInset: padded,
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
                  : SizedBox(width: double.infinity, child: body),
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
