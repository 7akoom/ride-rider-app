import 'package:flutter/widgets.dart';

import 'secure_window.dart';

/// Wrap a screen (or part of one) that shows sensitive content: while it is in the
/// tree, the window cannot be captured. See [SecureWindow].
class SecureScreen extends StatefulWidget {
  const SecureScreen({super.key, required this.child});

  final Widget child;

  @override
  State<SecureScreen> createState() => _SecureScreenState();
}

class _SecureScreenState extends State<SecureScreen> {
  @override
  void initState() {
    super.initState();
    SecureWindow.acquire();
  }

  @override
  void dispose() {
    SecureWindow.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
