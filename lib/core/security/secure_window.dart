import 'package:flutter/services.dart';

import '../error/error_reporter.dart';

/// Blocks screenshots, screen recording and the task-switcher preview while sensitive
/// content is on screen (wallet PIN, amounts, one-time codes). Android only; other
/// platforms ignore it.
///
/// Several screens can ask at once, so it counts: the window stays protected until the
/// last one lets go.
abstract final class SecureWindow {
  static const MethodChannel _channel = MethodChannel('rider_app/secure_window');

  static int _holders = 0;

  static Future<void> acquire() async {
    _holders++;
    if (_holders == 1) {
      await _call('enable');
    }
  }

  static Future<void> release() async {
    if (_holders == 0) {
      return;
    }

    _holders--;
    if (_holders == 0) {
      await _call('disable');
    }
  }

  static Future<void> _call(String method) async {
    try {
      await _channel.invokeMethod<void>(method);
    } on MissingPluginException {
      // Not Android: nothing to do.
    } on PlatformException catch (error, stack) {
      ErrorReporter.report(error, stack);
    }
  }
}
