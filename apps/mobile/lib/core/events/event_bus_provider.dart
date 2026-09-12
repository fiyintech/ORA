import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'event_subscription.dart';

/// Provider for the global EventBus singleton.
///
/// Usage:
/// ```dart
/// final eventBus = ref.read(eventBusProvider);
/// eventBus.subscribe<PostCreatedEvent>((event) {
///   // Handle post creation
/// });
/// ```
final eventBusProvider = Provider<EventBus>((ref) {
  return EventBus();
});