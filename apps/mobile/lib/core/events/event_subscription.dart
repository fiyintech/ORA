import 'ora_event.dart';

/// Represents a subscription to events of a specific type.
///
/// When created through [EventBus.subscribe], this object can be used
/// to unsubscribe from events when no longer needed.
class EventSubscription<T extends ORAEvent> {
  /// The event bus this subscription belongs to.
  final EventBus _eventBus;

  /// The callback to invoke when events are published.
  final void Function(T event) _callback;

  /// The type of events this subscription listens to.
  final Type _eventType;

  /// Creates a new EventSubscription.
  ///
  /// Should only be created by [EventBus.subscribe].
  EventSubscription(
    this._eventBus,
    this._eventType,
    this._callback,
  );

  /// Invokes the callback with the given event.
  ///
  /// Internal use only - called by [EventBus] when publishing events.
  void _notify(T event) {
    _callback(event);
  }

  /// Unsubscribes from future events.
  ///
  /// After calling this method, the callback will no longer be invoked.
  void cancel() {
    _eventBus._removeSubscription(this);
  }

  /// Returns the event type this subscription listens to.
  Type get eventType => _eventType;
}

/// The event bus for managing event subscriptions and publishing.
///
/// This is a simple, lightweight event bus implementation that supports
/// type-safe event handling without external dependencies.
class EventBus {
  /// Map of event types to their list of subscriptions.
  final Map<Type, List<EventSubscription>> _subscriptions = {};

  /// Subscribes to events of type [T].
  ///
  /// Returns an [EventSubscription] that can be used to unsubscribe.
  /// The [callback] will be invoked whenever an event of type [T] is published.
  EventSubscription<T> subscribe<T extends ORAEvent>(
    void Function(T event) callback,
  ) {
    final subscription = EventSubscription<T>(this, T, callback);
    _subscriptions.putIfAbsent(T, () => []).add(subscription);
    return subscription;
  }

  /// Publishes an event to all subscribers of its type.
  ///
  /// All subscribers of the exact event type will be notified synchronously.
  void publish<T extends ORAEvent>(T event) {
    final subscribers = _subscriptions[T]?.cast<EventSubscription<T>>() ?? [];
    for (final subscriber in subscribers) {
      subscriber._notify(event);
    }
  }

  /// Removes a subscription from the event bus.
  ///
  /// Internal use only - called by [EventSubscription.cancel].
  void _removeSubscription<T extends ORAEvent>(EventSubscription<T> subscription) {
    final subscribers = _subscriptions[subscription.eventType];
    if (subscribers != null) {
      subscribers.remove(subscription);
      if (subscribers.isEmpty) {
        _subscriptions.remove(subscription.eventType);
      }
    }
  }

  /// Clears all subscriptions for a specific event type.
  void clearSubscriptions<T extends ORAEvent>() {
    _subscriptions.remove(T);
  }

  /// Clears all subscriptions from the event bus.
  void clearAllSubscriptions() {
    _subscriptions.clear();
  }

  /// Returns the number of active subscriptions for a specific event type.
  int subscriptionCount<T extends ORAEvent>() {
    return _subscriptions[T]?.length ?? 0;
  }

  /// Returns the total number of active subscriptions across all event types.
  int get totalSubscriptionCount {
    return _subscriptions.values.fold(0, (sum, list) => sum + list.length);
  }
}