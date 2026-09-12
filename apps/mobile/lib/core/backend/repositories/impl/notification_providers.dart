import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/backend/repositories/notification_repository.dart';
import 'package:mobile/core/backend/repositories/impl/providers.dart';
import 'package:mobile/core/models/notification.dart';
import 'package:mobile/core/utils/result.dart';

// ──────────────────────────────────────────────────────────────
// Providers
// ──────────────────────────────────────────────────────────────

// notificationRepositoryProvider is imported from providers.dart

/// State for a single notification operation (for optimistic updates).
enum NotificationOperationStatus {
  initial,
  loading,
  success,
  failure,
}

/// State holder for notification operations with rollback support.
class NotificationOperationState {
  final NotificationOperationStatus status;
  final String? errorMessage;
  final NotificationModel? previousState;

  const NotificationOperationState({
    this.status = NotificationOperationStatus.initial,
    this.errorMessage,
    this.previousState,
  });

  NotificationOperationState copyWith({
    NotificationOperationStatus? status,
    String? errorMessage,
    NotificationModel? previousState,
  }) {
    return NotificationOperationState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      previousState: previousState ?? this.previousState,
    );
  }
}

/// Notifier for managing notification state with optimistic updates and realtime.
class NotificationNotifier extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final NotificationRepository _repository;
  StreamSubscription<NotificationModel>? _realtimeSubscription;
  final String _userId;
  final Set<String> _seenNotificationIds = {};

  NotificationNotifier(this._repository, this._userId)
      : super(const AsyncValue.loading()) {
    loadNotifications();
    _subscribeToRealtime();
  }

  // ──────────────────────────────────────────────────────────────
  // Load Notifications
  // ──────────────────────────────────────────────────────────────

  /// Loads notifications from the repository.
  Future<void> loadNotifications() async {
    state = const AsyncValue.loading();
    
    final result = await _repository.loadNotifications(_userId);
    
    result.when(
      success: (notifications) {
        // Track seen notification IDs to prevent duplicates
        _seenNotificationIds.clear();
        _seenNotificationIds.addAll(notifications.map((n) => n.id));
        state = AsyncValue.data(notifications);
      },
      failure: (error) {
        state = AsyncValue.error(error, StackTrace.current);
      },
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Realtime Subscription
  // ──────────────────────────────────────────────────────────────

  /// Subscribes to realtime notifications.
  void _subscribeToRealtime() {
    _realtimeSubscription = _repository.watchNotifications(_userId).listen(
      (notification) {
        // Prevent duplicate notifications
        if (_seenNotificationIds.contains(notification.id)) {
          return;
        }

        _seenNotificationIds.add(notification.id);

        // Add the new notification to the state
        state.whenOrNull(
          data: (notifications) {
            final updated = [notification, ...notifications];
            state = AsyncValue.data(updated);
          },
          loading: () {
            // If still loading, just track the ID
          },
          error: (error, stack) {
            // If in error state, try to recover
            state = AsyncValue.data([notification]);
          },
        );
      },
      onError: (error) {
        // Log error but don't crash the notifier
        // The stream will automatically try to reconnect
      },
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Optimistic Updates
  // ──────────────────────────────────────────────────────────────

  /// Marks a notification as read with optimistic update.
  Future<void> markAsRead(String notificationId) async {
    // Store previous state for rollback
    final previousState = state.value;
    if (previousState == null) return;

    // Find the notification to update
    final notificationIndex = previousState.indexWhere(
      (n) => n.id == notificationId,
    );
    if (notificationIndex == -1) return;

    final notification = previousState[notificationIndex];
    if (notification.isRead) return; // Already read

    // Optimistic update
    final optimisticNotification = notification.copyWith(isRead: true);
    final optimisticList = List<NotificationModel>.from(previousState);
    optimisticList[notificationIndex] = optimisticNotification;
    state = AsyncValue.data(optimisticList);

    // Perform actual update
    final result = await _repository.markAsRead(notificationId);

    // Rollback on failure
    if (result.isFailure) {
      state = AsyncValue.data(previousState);
    }
  }

  /// Marks all notifications as read with optimistic update.
  Future<void> markAllAsRead() async {
    // Store previous state for rollback
    final previousState = state.value;
    if (previousState == null) return;

    // Check if all are already read
    final hasUnread = previousState.any((n) => !n.isRead);
    if (!hasUnread) return;

    // Optimistic update
    final optimisticList = previousState
        .map((n) => n.copyWith(isRead: true))
        .toList();
    state = AsyncValue.data(optimisticList);

    // Perform actual update
    final result = await _repository.markAllAsRead(_userId);

    // Rollback on failure
    if (result.isFailure) {
      state = AsyncValue.data(previousState);
    }
  }

  /// Deletes a notification with optimistic update.
  Future<void> deleteNotification(String notificationId) async {
    // Store previous state for rollback
    final previousState = state.value;
    if (previousState == null) return;

    // Find the notification to delete
    final notificationIndex = previousState.indexWhere(
      (n) => n.id == notificationId,
    );
    if (notificationIndex == -1) return;

    final notification = previousState[notificationIndex];

    // Optimistic update
    final optimisticList = List<NotificationModel>.from(previousState);
    optimisticList.removeAt(notificationIndex);
    state = AsyncValue.data(optimisticList);

    // Perform actual delete
    final result = await _repository.deleteNotification(notificationId);

    // Rollback on failure
    if (result.isFailure) {
      state = AsyncValue.data(previousState);
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Unread Count
  // ──────────────────────────────────────────────────────────────

  /// Gets the count of unread notifications.
  Future<int> getUnreadCount() async {
    final result = await _repository.getUnreadCount(_userId);
    return result.when(
      success: (count) => count,
      failure: (_) => 0,
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Lifecycle
  // ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }
}

// ──────────────────────────────────────────────────────────────
// Provider Definitions
// ──────────────────────────────────────────────────────────────

/// Provider for the notification notifier.
/// 
/// Requires the user ID to be provided.
final notificationNotifierProvider = StateNotifierProvider.family
    .autoDispose<NotificationNotifier, AsyncValue<List<NotificationModel>>, String>(
  (ref, userId) {
    final repository = ref.watch(notificationRepositoryProvider);
    return NotificationNotifier(repository, userId);
  },
);

/// Provider for notifications list.
final notificationProvider = Provider.family<AsyncValue<List<NotificationModel>>, String>(
  (ref, userId) {
    return ref.watch(notificationNotifierProvider(userId));
  },
);

/// Provider for unread notification count.
final notificationUnreadCountProvider = FutureProvider.family<int, String>(
  (ref, userId) {
    final notifier = ref.watch(notificationNotifierProvider(userId).notifier);
    return notifier.getUnreadCount();
  },
);