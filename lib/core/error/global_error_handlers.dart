import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'error_reporter.dart';
import 'friendly_error_widget.dart';

/// Catches every error nothing else caught, so none of them reaches the rider as a
/// technical message or a red screen.
void installGlobalErrorHandlers() {
  FlutterError.onError = (details) {
    if (kDebugMode) {
      // The developer's console only.
      FlutterError.dumpErrorToConsole(details);
    }

    ErrorReporter.report(details.exception, details.stack);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    ErrorReporter.report(error, stack);

    return true;
  };

  ErrorWidget.builder = (_) => const FriendlyErrorWidget();
}
