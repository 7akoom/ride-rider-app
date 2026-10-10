import 'error_reporter.dart';
import 'failure.dart';
import 'failure_mapper.dart';
import 'result.dart';

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
