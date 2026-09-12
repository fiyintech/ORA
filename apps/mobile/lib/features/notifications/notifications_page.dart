import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/backend/repositories/impl/notification_providers.dart';
import 'package:mobile/core/models/notification.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/core/theme/ora_radius.dart';
import 'package:mobile/core/theme/ora_spacing.dart';
import 'package:mobile/core/theme/ora_typography.dart';
import 'package:mobile/features/notifications/widgets/notification_empty_state.dart';
import 'package:mobile/features/notifications/widgets/notification_group.dart';
import 'package:mobile/features/notifications/widgets/notification_tile.dart';
import 'package:mobile/features/session/session_provider.dart';
import 'package:mobile/shared/widgets/ora_auth_guard.dart';
import 'package:mobile/shared/widgets/ora_loading_indicator.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  final ScrollController _scrollController = ScrollController();
  final int _pageSize = 20;
  int _currentPage = 0;
  bool _isLoadingMore = false;
  bool _hasMoreNotifications = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreNotifications();
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoadingMore || !_hasMoreNotifications) return;

    final userId = ref.read(currentUserProvider)?.id ?? '';
    if (userId.isEmpty) return;

    final notificationsAsync = ref.read(notificationProvider(userId));

    notificationsAsync.whenOrNull(
      data: (notifications) {
        if (notifications.length < (_currentPage + 1) * _pageSize) {
          _hasMoreNotifications = false;
          return;
        }

        setState(() {
          _isLoadingMore = true;
          _currentPage++;
        });

        // In a real implementation, this would fetch the next page
        // For now, we just simulate loading
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _isLoadingMore = false;
            });
          }
        });
      },
    );
  }

  Future<void> _handleRefresh() async {
    final userId = ref.read(currentUserProvider)?.id ?? '';
    if (userId.isEmpty) return;
    
    final notifier = ref.read(notificationNotifierProvider(userId).notifier);
    await notifier.loadNotifications();
    
    setState(() {
      _currentPage = 0;
      _hasMoreNotifications = true;
    });
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Mark as read
    final notifier = ref.read(notificationNotifierProvider(
      notification.recipientId,
    ).notifier);
    notifier.markAsRead(notification.id);

    // Navigate based on notification type
    switch (notification.type) {
      case NotificationType.like:
      case NotificationType.comment:
      case NotificationType.reply:
        // Navigate to post
        if (notification.postId != null) {
          // TODO: Navigate to post detail
          // context.push('/post/${notification.postId}');
        }
        break;
      case NotificationType.follow:
        // Navigate to actor profile
        if (notification.actor != null) {
          // TODO: Navigate to profile
          // context.push('/profile-public/${notification.actorId}');
        }
        break;
    }
  }

  Future<void> _handleDelete(NotificationModel notification) async {
    final notifier = ref.read(notificationNotifierProvider(
      notification.recipientId,
    ).notifier);
    await notifier.deleteNotification(notification.id);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final userId = ref.watch(currentUserProvider)?.id ?? '';

    return AuthGuard(
      child: Scaffold(
        backgroundColor: ORAColors.background(brightness),
        appBar: AppBar(
          backgroundColor: ORAColors.background(brightness),
          elevation: 0,
          scrolledUnderElevation: 0,
          titleSpacing: ORASpacing.lg,
          title: Row(
            children: [
              Text(
                'Notifications',
                style: ORATypography.title(context),
              ),
              _buildUnreadBadge(brightness),
            ],
          ),
          actions: [
            _buildMarkAllReadButton(brightness),
            const SizedBox(width: ORASpacing.sm),
          ],
        ),
        body: _buildBody(brightness, userId),
      ),
    );
  }

  Widget _buildUnreadBadge(Brightness brightness) {
    final userId = ref.read(currentUserProvider)?.id ?? '';
    if (userId.isEmpty) return const SizedBox.shrink();
    
    final unreadCountAsync = ref.watch(notificationUnreadCountProvider(userId));

    return unreadCountAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (count) {
        if (count == 0) return const SizedBox.shrink();
        
        return Container(
          margin: const EdgeInsets.only(left: ORASpacing.sm),
          padding: const EdgeInsets.symmetric(
            horizontal: ORASpacing.sm,
            vertical: ORASpacing.xs,
          ),
          decoration: BoxDecoration(
            color: ORAColors.primary(brightness),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: ORATypography.caption(context).copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMarkAllReadButton(Brightness brightness) {
    final userId = ref.read(currentUserProvider)?.id ?? '';
    if (userId.isEmpty) return const SizedBox.shrink();
    
    final notificationsAsync = ref.watch(notificationProvider(userId));

    return notificationsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (notifications) {
        final hasUnread = notifications.any((n) => !n.isRead);
        if (!hasUnread) return const SizedBox.shrink();

        return TextButton(
          onPressed: () async {
            final notifier = ref.read(notificationNotifierProvider(userId).notifier);
            await notifier.markAllAsRead();
          },
          child: Text(
            'Mark all read',
            style: ORATypography.label(context).copyWith(
              color: ORAColors.primary(brightness),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(Brightness brightness, String userId) {
    final notificationsAsync = ref.watch(notificationProvider(userId));

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: ORAColors.primary(brightness),
      child: notificationsAsync.when(
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(error),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const NotificationEmptyState();
          }

          return _buildNotificationsList(notifications);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(ORASpacing.lg),
      itemCount: 10,
      itemBuilder: (context, index) => _buildShimmerTile(),
    );
  }

  Widget _buildShimmerTile() {
    return Container(
      margin: const EdgeInsets.only(bottom: ORASpacing.sm),
      padding: const EdgeInsets.all(ORASpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: ORARadius.mediumAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shimmer avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: ORASpacing.md),
          // Shimmer content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: ORARadius.smallAll,
                  ),
                ),
                const SizedBox(height: ORASpacing.xs),
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: ORARadius.smallAll,
                  ),
                ),
                const SizedBox(height: ORASpacing.xs),
                Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: ORARadius.smallAll,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    final brightness = Theme.of(context).brightness;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ORASpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: ORAColors.textSecondary(brightness),
            ),
            const SizedBox(height: ORASpacing.lg),
            Text(
              'Something went wrong',
              style: ORATypography.title(context),
            ),
            const SizedBox(height: ORASpacing.sm),
            Text(
              'Please try again later',
              style: ORATypography.body(context).copyWith(
                color: ORAColors.textSecondary(brightness),
              ),
            ),
            const SizedBox(height: ORASpacing.lg),
            ElevatedButton(
              onPressed: _handleRefresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList(List<NotificationModel> notifications) {
    final groups = NotificationGrouper.group(notifications);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: ORASpacing.lg),
      itemCount: groups.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == groups.length) {
          // Loading more indicator
          return _buildLoadingMoreIndicator();
        }

        final group = groups[index];
        return NotificationGroup(
          title: group.title,
          notifications: group.notifications,
          itemBuilder: (notification) => NotificationTile(
            notification: notification,
            onTap: () => _handleNotificationTap(notification),
            onDelete: () => _handleDelete(notification),
          ),
        );
      },
    );
  }

  Widget _buildLoadingMoreIndicator() {
    if (!_isLoadingMore) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(ORASpacing.lg),
      alignment: Alignment.center,
      child: const ORALoadingIndicator(size: 24),
    );
  }
}

// Extension removed - using currentUserProvider from session_provider.dart