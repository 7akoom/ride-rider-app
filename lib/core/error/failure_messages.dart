import '../l10n/l10n.dart';
import 'failure.dart';

/// The message the rider sees for a failure, in their language.
///
/// This is the generic message. A feature that knows a better one for a specific
/// [BackendFailure.reason] picks it first and falls back to this.
extension FailureMessage on Failure {
  String message(AppLocalizations l10n) {
    return switch (this) {
      NetworkFailure() => l10n.errorNoConnection,
      TimeoutFailure() => l10n.errorTimeout,
      UnexpectedFailure() => l10n.errorUnexpected,
      SessionExpiredFailure() => l10n.errorSessionExpired,
      ForbiddenFailure() => l10n.errorForbidden,
      NotFoundFailure() => l10n.errorNotFound,
      ConflictFailure() => l10n.errorConflict,
      RateLimitedFailure() => l10n.errorTooManyRequests,
      InvalidInputFailure() => l10n.errorInvalidInput,
      PreconditionFailure() => l10n.errorNotAllowedNow,
      ServerFailure() => l10n.errorServer,
    };
  }
}
