import 'package:flutter/material.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/failure_messages.dart';
import '../../../core/l10n/l10n.dart';
import 'empty_state.dart';

/// What a screen shows when loading failed: the failure's translated message and a
/// "Try again" button. Never a technical message.
class FailureView extends StatelessWidget {
  const FailureView({
    super.key,
    required this.failure,
    required this.onRetry,
    this.message,
  });

  final Failure failure;
  final VoidCallback onRetry;

  /// A more specific message the feature already chose; the generic one otherwise.
  final String? message;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isOffline = failure is NetworkFailure || failure is TimeoutFailure;

    return EmptyState(
      icon: isOffline ? Icons.wifi_off_rounded : Icons.error_outline,
      message: message ?? failure.message(l10n),
      actionLabel: l10n.actionRetry,
      onAction: onRetry,
    );
  }
}
