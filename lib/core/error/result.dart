import 'failure.dart';

/// The outcome of a repository or use-case call: a value or a [Failure], never an
/// exception. The presentation layer only ever receives these.
///
/// Pure Dart, so the domain layer can use it; the data layer makes them with `guard`
/// (guard.dart).
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
