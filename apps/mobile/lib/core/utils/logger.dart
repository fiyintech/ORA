/// Lightweight logging utility for ORA.
///
/// Supports info, warning, and error levels.
/// No analytics or external services.
///
/// Usage:
/// ```dart
/// Logger.info('User logged in', tag: 'Auth');
/// Logger.warning('Cache miss', tag: 'Cache');
/// Logger.error('API failed', error: e, stackTrace: stack);
/// ```
class Logger {
  /// Whether logging is enabled.
  /// Set to false in production builds.
  static bool enabled = true;

  /// Log an informational message.
  static void info(String message, {String? tag}) {
    if (!enabled) return;
    // ignore: avoid_print
    print(_format('INFO', message, tag));
  }

  /// Log a warning message.
  static void warning(String message, {String? tag}) {
    if (!enabled) return;
    // ignore: avoid_print
    print(_format('WARN', message, tag));
  }

  /// Log an error message with optional error and stack trace.
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    if (!enabled) return;
    // ignore: avoid_print
    print(_format('ERROR', message, tag));
    if (error != null) {
      // ignore: avoid_print
      print('  Error: $error');
    }
    if (stackTrace != null) {
      // ignore: avoid_print
      print('  Stack: $stackTrace');
    }
  }

  static String _format(String level, String message, String? tag) {
    final timestamp = DateTime.now().toIso8601String();
    final tagStr = tag != null ? '[$tag]' : '';
    return '[$timestamp] $level$tagStr: $message';
  }
}
