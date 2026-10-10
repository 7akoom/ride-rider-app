import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/error/failure_messages.dart';
import 'package:rider_app/core/l10n/app_locales.dart';
import 'package:rider_app/core/l10n/l10n.dart';

const List<Failure> _all = [
  NetworkFailure(),
  TimeoutFailure(),
  UnexpectedFailure(),
  SessionExpiredFailure(),
  ForbiddenFailure(),
  NotFoundFailure(),
  ConflictFailure(),
  RateLimitedFailure(),
  InvalidInputFailure(),
  PreconditionFailure(),
  ServerFailure(),
];

void main() {
  for (final locale in AppLocales.all) {
    test('every failure has a message in ${locale.languageCode}', () {
      final l10n = lookupAppLocalizations(locale);

      for (final failure in _all) {
        expect(failure.message(l10n).trim(), isNotEmpty, reason: '$failure');
      }
    });
  }

  test('Arabic and Kurdish messages are not the English ones', () {
    final english = lookupAppLocalizations(AppLocales.english);

    for (final locale in [AppLocales.arabic, AppLocales.kurdish]) {
      final other = lookupAppLocalizations(locale);

      for (final failure in _all) {
        expect(failure.message(other), isNot(failure.message(english)));
      }
    }
  });
}
