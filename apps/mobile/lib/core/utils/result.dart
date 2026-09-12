/// A type that represents either a success or a failure.
///
/// Use this instead of throwing raw exceptions for API calls.
///
/// Example:
/// ```dart
/// Result<User> result = await userRepository.getById('123');
/// result.when(
///   success: (user) => print('Got user: $user'),
///   failure: (failure) => print('Error: ${failure.message}'),
/// );
/// ```
class Result<T> {
  final T? _value;
  final Failure? _failure;

  const Result.success(T value)
      : _value = value,
        _failure = null;

  const Result.failure(Failure failure)
      : _value = null,
        _failure = failure;

  /// Returns true if this is a success.
  bool get isSuccess => _failure == null;

  /// Returns true if this is a failure.
  bool get isFailure => _failure != null;

  /// Returns the success value, or null if this is a failure.
  T? get value => _value;

  /// Returns the failure, or null if this is a success.
  Failure? get failure => _failure;

  /// Returns the success value, or throws if this is a failure.
  T getOrThrow() {
    if (_failure != null) {
      throw _failure;
    }
    return _value as T;
  }

  /// Returns the success value, or [defaultValue] if this is a failure.
  T getOrDefault(T defaultValue) {
    if (_failure != null) {
      return defaultValue;
    }
    return _value as T;
  }

  /// Executes the appropriate callback based on success or failure.
  R when<R>({
    required R Function(T value) success,
    required R Function(Failure failure) failure,
  }) {
    if (_failure != null) {
      return failure(_failure);
    }
    return success(_value as T);
  }

  /// Executes the appropriate callback based on success or failure.
  /// Both callbacks are nullable — only the relevant one is called.
  void whenOrNull({
    void Function(T value)? success,
    void Function(Failure failure)? failure,
  }) {
    if (_failure != null) {
      failure?.call(_failure);
    } else {
      success?.call(_value as T);
    }
  }

  @override
  String toString() {
    if (_failure != null) {
      return 'Result.failure($_failure)';
    }
    return 'Result.success($_value)';
  }
}

/// Represents a failure in an operation.
///
/// Contains a message and optional error/stack trace for debugging.
class Failure {
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  const Failure(
    this.message, {
    this.error,
    this.stackTrace,
  });

  @override
  String toString() => 'Failure(message: $message)';
}
