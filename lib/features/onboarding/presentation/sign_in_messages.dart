import '../../../core/error/failure.dart';
import '../../../core/error/failure_messages.dart';
import '../../../core/l10n/l10n.dart';
import '../domain/problems/sign_in_problems.dart';

/// What to tell the rider when a code could not be sent.
String sendCodeMessage(AppLocalizations l10n, Failure failure) {
  return switch (sendCodeProblemOf(failure)) {
    SendCodeProblem.invalidNumber => l10n.phoneInvalid,
    SendCodeProblem.tooManyRequests => l10n.sendCodeTooMany,
    SendCodeProblem.cannotSendNow => l10n.sendCodeUnavailable,
    null => failure.message(l10n),
  };
}

/// What to tell the rider when a typed code was refused.
String codeMessage(AppLocalizations l10n, Failure failure) {
  return switch (codeProblemOf(failure)) {
    CodeProblem.wrongCode => l10n.codeWrong,
    CodeProblem.expired => l10n.codeExpired,
    CodeProblem.tooManyTries => l10n.codeTooManyTries,
    CodeProblem.accountBlocked => l10n.accountBlocked,
    null => failure.message(l10n),
  };
}
