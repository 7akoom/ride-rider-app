import 'dart:async';

import 'package:flutter/widgets.dart';

/// Rebuilds once a second until [until], giving [builder] the time left (zero once it
/// has passed). For "resend in 0:43" and similar.
class CountdownBuilder extends StatefulWidget {
  const CountdownBuilder({
    super.key,
    required this.until,
    required this.builder,
    this.now = DateTime.now,
  });

  final DateTime until;
  final Widget Function(BuildContext context, Duration remaining) builder;

  /// The clock; tests pass their own.
  final DateTime Function() now;

  @override
  State<CountdownBuilder> createState() => _CountdownBuilderState();
}

class _CountdownBuilderState extends State<CountdownBuilder> {
  Timer? _tick;

  Duration get _remaining {
    final left = widget.until.difference(widget.now());

    return left.isNegative ? Duration.zero : left;
  }

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(CountdownBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.until != widget.until) {
      _start();
    }
  }

  void _start() {
    _tick?.cancel();

    if (_remaining == Duration.zero) {
      return;
    }

    _tick = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {});

      if (_remaining == Duration.zero) {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _remaining);
}
