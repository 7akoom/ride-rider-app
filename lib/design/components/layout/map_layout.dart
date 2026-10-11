import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A screen whose map fills it, with a panel over the map's bottom. The map keeps its
/// size whatever the panel does: a map that changes size flickers on Android, and one
/// resized while its screen closes can bring the app down.
///
/// [map] is told how much of its bottom the panel covers, to frame a route in the part
/// left open. The panel takes at most [panelShare] of the height and scrolls beyond.
class MapLayout extends StatefulWidget {
  const MapLayout({
    super.key,
    required this.map,
    required this.panel,
    this.panelShare = 0.6,
    this.marker,
    this.buttons,
  });

  final Widget Function(double covered) map;
  final Widget panel;
  final double panelShare;

  /// Drawn on the map and never touched (a pin, rings); told how much is covered.
  final Widget Function(double covered)? marker;

  /// Buttons over the map, in the space just above the panel.
  final Widget? buttons;

  @override
  State<MapLayout> createState() => _MapLayoutState();
}

class _MapLayoutState extends State<MapLayout> {
  /// The panel's height once laid out; until then, the most it may take.
  double? _panel;

  void _measured(double height) {
    if (mounted && height != _panel) {
      setState(() => _panel = height);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final most = box.maxHeight * widget.panelShare;
        final covered = _panel ?? most;
        final marker = widget.marker;

        return Stack(
          children: [
            Positioned.fill(child: widget.map(covered)),
            if (marker != null) Positioned.fill(child: IgnorePointer(child: marker(covered))),
            Positioned.fill(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: widget.buttons ?? const SizedBox.shrink()),
                  _HeightReporter(
                    onHeight: _measured,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: most),
                      child: SingleChildScrollView(child: widget.panel),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Tells its height after each layout that changed it.
class _HeightReporter extends SingleChildRenderObjectWidget {
  const _HeightReporter({required this.onHeight, required super.child});

  final ValueChanged<double> onHeight;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderHeightReporter(onHeight);

  @override
  void updateRenderObject(BuildContext context, _RenderHeightReporter renderObject) {
    renderObject.onHeight = onHeight;
  }
}

class _RenderHeightReporter extends RenderProxyBox {
  _RenderHeightReporter(this.onHeight);

  ValueChanged<double> onHeight;
  double? _last;

  @override
  void performLayout() {
    super.performLayout();
    final height = size.height;

    if (height != _last) {
      _last = height;
      // Not during layout: the screen is told once this frame is done.
      WidgetsBinding.instance.addPostFrameCallback((_) => onHeight(height));
    }
  }
}
