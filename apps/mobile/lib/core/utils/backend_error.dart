import 'package:flutter/foundation.dart';
import 'package:mobile/core/utils/logger.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// User-facing message for a backend failure. Does not include row data,
/// SQL, or request payloads.
String describeBackendError(Object error) {
  if (error is PostgrestException) {
    final code = error.code ?? 'unknown';
    return 'Database error ($code): ${error.message}';
  }
  if (error is AuthException) {
    return error.message;
  }
  if (error is StorageException) {
    return 'Storage error: ${error.message}';
  }
  return 'Request failed. Check your connection and try again.';
}

Failure backendFailure(Object error, [StackTrace? stackTrace]) {
  return Failure(
    describeBackendError(error),
    error: error,
    stackTrace: stackTrace,
  );
}

/// Logs enough to diagnose RLS/schema issues without printing full payloads.
void logBackendError(
  String operation,
  Object error,
  StackTrace stack, {
  required String tag,
}) {
  if (kReleaseMode) {
    Logger.error('$operation failed (${error.runtimeType})', tag: tag);
    return;
  }

  if (error is PostgrestException) {
    Logger.error(
      '$operation failed — PostgrestException code=${error.code} message=${error.message}',
      tag: tag,
    );
    return;
  }

  Logger.error(
    '$operation failed (${error.runtimeType})',
    error: error,
    stackTrace: stack,
    tag: tag,
  );
}
