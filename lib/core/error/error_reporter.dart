import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../security/redactor.dart';

/// Where unexpected errors go. Never to the rider's screen.
///
/// Debug builds log them, redacted. Release builds keep nothing for now; a crash
/// reporting service plugs in here later (and receives redacted text only).
abstract final class ErrorReporter {
  static void report(Object error, StackTrace? stack) {
    if (!kDebugMode) {
      return;
    }

    developer.log(
      Redactor.redact(error.toString()),
      name: 'rider_app',
      stackTrace: stack,
    );
  }
}
