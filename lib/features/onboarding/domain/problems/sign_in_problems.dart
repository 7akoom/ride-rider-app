import '../../../../core/error/failure.dart';

/// Why a login code could not be sent, when the screen can say something more useful
/// than the general failure message.
enum SendCodeProblem {
  /// The backend did not accept the number.
  invalidNumber,

  /// Too many codes asked for: wait a little.
  tooManyRequests,

  /// Codes cannot be delivered right now (the messaging provider is down).
  cannotSendNow,
}

/// Why a typed login code was refused.
enum CodeProblem {
  /// The code is not the one that was sent.
  wrongCode,

  /// The code ran out, was used, or was replaced: ask for a new one.
  expired,

  /// Too many wrong tries for this code: ask for a new one.
  tooManyTries,

  /// The account is suspended: contact support.
  accountBlocked,
}

/// Null means the failure has nothing to do with the number (offline, server error):
/// the screen shows the failure's general message.
SendCodeProblem? sendCodeProblemOf(Failure failure) => switch (failure) {
      InvalidInputFailure() => SendCodeProblem.invalidNumber,
      RateLimitedFailure() => SendCodeProblem.tooManyRequests,
      PreconditionFailure() => SendCodeProblem.cannotSendNow,
      _ => null,
    };

/// Matches the identity service's answers to VerifyLoginOTP: a wrong code is
/// Unauthenticated (seen here as [SessionExpiredFailure]), an expired, used or
/// cancelled challenge is NotFound or FailedPrecondition, too many tries is
/// ResourceExhausted, and a suspended account is PermissionDenied.
CodeProblem? codeProblemOf(Failure failure) => switch (failure) {
      SessionExpiredFailure() || InvalidInputFailure() => CodeProblem.wrongCode,
      NotFoundFailure() || PreconditionFailure() => CodeProblem.expired,
      RateLimitedFailure() => CodeProblem.tooManyTries,
      ForbiddenFailure() => CodeProblem.accountBlocked,
      _ => null,
    };
