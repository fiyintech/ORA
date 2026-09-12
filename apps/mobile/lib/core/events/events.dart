/// Event system for the ORA application.
///
/// This library provides a lightweight event bus implementation
/// with type-safe event handling and Riverpod integration.
///
/// ## Usage
///
/// ```dart
/// import 'package:flutter_riverpod/flutter_riverpod.dart';
/// import 'core/events/events.dart';
///
/// // Get the event bus
/// final eventBus = ref.read(eventBusProvider);
///
/// // Subscribe to events
/// final subscription = eventBus.subscribe<PostCreatedEvent>((event) {
///   print('Post created: ${event.postId}');
/// });
///
/// // Publish events
/// eventBus.publish(PostCreatedEvent(
///   postId: '123',
///   userId: 'user_456',
/// ));
///
/// // Unsubscribe when done
/// subscription.cancel();
/// ```
library;

export 'ora_event.dart';
export 'event_subscription.dart';
export 'event_bus_provider.dart';
export 'event_classes.dart';
