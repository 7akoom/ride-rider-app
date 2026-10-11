import 'dart:async';

import 'package:flutter/widgets.dart';

/// Rebuilds once a second, giving [builder] the time since [since] (zero before it).
/// For "waiting for you for 2:38" and similar.
class ElapsedBuilder extends StatefulWidget {
  const ElapsedBuilder({
    super.key,
    required this.since,
    required this.builder,
    this.now = DateTime.now,
  });

  final DateTime since;
  final Widget Function(BuildContext context, Duration elapsed) builder;

  /// The clock; tests pass their own.
  final DateTime Function() now;

  @override
  State<ElapsedBuilder> createState() => _ElapsedBuilderState();
}

class _ElapsedBuilderState extends State<ElapsedBuilder> {
  late final Timer _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = widget.now().difference(widget.since);

    return widget.builder(context, elapsed.isNegative ? Duration.zero : elapsed);
  }
}
