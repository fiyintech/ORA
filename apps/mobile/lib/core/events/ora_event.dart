// Import needed for Random
import 'dart:math';

/// Base class for all events in the ORA application.
///
/// All domain events should extend this class.
abstract class ORAEvent {
  /// Unique identifier for this event instance.
  final String id;

  /// Timestamp when the event occurred.
  final DateTime timestamp;

  /// Optional metadata associated with the event.
  final Map<String, dynamic> metadata;

  /// Creates a new ORAEvent.
  ///
  /// If [id] is not provided, a UUID v4 will be generated.
  /// If [timestamp] is not provided, the current time will be used.
  /// [metadata] can be used to attach additional context to the event.
  ORAEvent({
    String? id,
    DateTime? timestamp,
    this.metadata = const {},
  })  : id = id ?? _generateId(),
        timestamp = timestamp ?? DateTime.now();

  /// Generates a unique identifier for events.
  static String _generateId() {
    // Simple ID generation for now - in production you might want to use
    // a proper UUID library, but we're keeping it lightweight per requirements.
    return 'event_${DateTime.now().microsecondsSinceEpoch}_${_randomString(8)}';
  }

  /// Generates a random string of the given length.
  static String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  /// Returns a string representation of the event.
  @override
  String toString() {
    return '$runtimeType(id: $id, timestamp: $timestamp)';
  }
}
