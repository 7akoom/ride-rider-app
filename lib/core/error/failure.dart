/// Why something the rider asked for did not work, in terms the app can act on.
///
/// Every error, wherever it starts (network, backend, plugin, a bug), ends up as one of
/// these before it reaches the presentation layer. Each kind has its own translated
/// message (failure_messages.dart); features can show a more specific message by
/// looking at [BackendFailure.reason].
sealed class Failure {
  const Failure();
}

/// The request never reached the server (offline, DNS, connection refused).
final class NetworkFailure extends Failure {
  const NetworkFailure();
}

/// The server did not answer in time.
final class TimeoutFailure extends Failure {
  const TimeoutFailure();
}

/// Something failed that has no better description (a bug, a plugin error, a reply in
/// an unexpected shape).
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure();
}

/// The backend answered and refused the request.
sealed class BackendFailure extends Failure {
  const BackendFailure({this.reason});

  /// The backend's machine-readable reason, when it sent one.
  final String? reason;
}

/// The session could not be renewed; the rider has to sign in again.
final class SessionExpiredFailure extends BackendFailure {
  const SessionExpiredFailure({super.reason});
}

final class ForbiddenFailure extends BackendFailure {
  const ForbiddenFailure({super.reason});
}

final class NotFoundFailure extends BackendFailure {
  const NotFoundFailure({super.reason});
}

/// Already done, or the data changed underneath (409).
final class ConflictFailure extends BackendFailure {
  const ConflictFailure({super.reason});
}

final class RateLimitedFailure extends BackendFailure {
  const RateLimitedFailure({super.reason});
}

/// The input was rejected (gRPC InvalidArgument / OutOfRange).
final class InvalidInputFailure extends BackendFailure {
  const InvalidInputFailure({super.reason});
}

/// The request is fine but not allowed in the current state (gRPC FailedPrecondition),
/// for example a trip requested while dues are unpaid.
final class PreconditionFailure extends BackendFailure {
  const PreconditionFailure({super.reason});
}

/// The server failed (5xx).
final class ServerFailure extends BackendFailure {
  const ServerFailure({super.reason});
}
