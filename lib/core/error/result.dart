import 'error_reporter.dart';
import 'failure.dart';
import 'failure_mapper.dart';

/// The outcome of a repository or use-case call: a value or a [Failure], never an
/// exception. The presentation layer only ever receives these.
sealed class Result<T> {
  const Result();

  R fold<R>(R Function(T value) onOk, R Function(Failure failure) onErr) {
    return switch (this) {
      Ok<T>(:final value) => onOk(value),
      Err<T>(:final failure) => onErr(failure),
    };
  }
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;
}

/// Runs [body] and catches everything it throws as a [Failure].
///
/// Data-layer code wraps every backend call in this. Failures that point to a bug
/// (not a refusal from the backend or a connection problem) are reported.
Future<Result<T>> guard<T>(Future<T> Function() body) async {
  try {
    return Ok(await body());
  } catch (error, stack) {
    final failure = mapToFailure(error);

    if (failure is UnexpectedFailure) {
      ErrorReporter.report(error, stack);
    }

    return Err(failure);
  }
}
