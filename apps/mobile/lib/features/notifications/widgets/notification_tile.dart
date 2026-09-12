import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/backend/repositories/impl/notification_providers.dart';
import 'package:mobile/core/models/notification.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/core/theme/ora_radius.dart';
import 'package:mobile/core/theme/ora_spacing.dart';
import 'package:mobile/core/theme/ora_typography.dart';

/// ORA Design System — Notification Tile
///
/// Displays a single notification with avatar, content, timestamp,
/// and unread indicator. Supports swipe actions for mark read and delete.
class NotificationTile extends ConsumerWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final isUnread = !notification.isRead;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right: mark as read
          final notifier = ref.read(notificationNotifierProvider(
            notification.recipientId,
          ).notifier);
          await notifier.markAsRead(notification.id);
          return false; // Don't dismiss the tile
        } else if (direction == DismissDirection.endToStart) {
          // Swipe left: delete
          if (onDelete != null) {
            onDelete!();
          }
          return true; // Dismiss the tile
        }
        return false;
      },
      background: _buildSwipeBackground(
        context,
        brightness,
        isLeftSwipe: false,
      ),
      secondaryBackground: _buildSwipeBackground(
        context,
        brightness,
        isLeftSwipe: true,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(
            left: ORASpacing.lg,
            right: ORASpacing.lg,
            bottom: ORASpacing.sm,
          ),
          padding: const EdgeInsets.all(ORASpacing.md),
          decoration: BoxDecoration(
            color: isUnread
                ? ORAColors.primary(brightness).withValues(alpha: 0.05)
                : ORAColors.surface(brightness),
            borderRadius: ORARadius.mediumAll,
            border: Border.all(
              color: isUnread
                  ? ORAColors.primary(brightness).withValues(alpha: 0.2)
                  : ORAColors.border(brightness),
              width: 1,
            ),
            boxShadow: isUnread
                ? [
                    BoxShadow(
                      color: ORAColors.primary(brightness).withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              _buildAvatar(context, brightness),
              const SizedBox(width: ORASpacing.md),
              // Content
              Expanded(
                child: _buildContent(context, brightness, isUnread),
              ),
              // Unread indicator
              if (isUnread) _buildUnreadIndicator(brightness),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, Brightness brightness) {
    final avatarUrl = notification.actor?.avatarUrl;
    final username = notification.actor?.username ?? 'User';

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: ORAColors.border(brightness),
          width: 1,
        ),
      ),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl.isNotEmpty
            ? Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildAvatarPlaceholder(context, brightness, username);
                },
              )
            : _buildAvatarPlaceholder(context, brightness, username),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(BuildContext context, Brightness brightness, String username) {
    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';
    
    return Container(
      color: ORAColors.primary(brightness).withValues(alpha: 0.1),
      child: Center(
        child: Text(
          initial,
          style: ORATypography.label(context).copyWith(
            color: ORAColors.primary(brightness),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Brightness brightness, bool isUnread) {
    final actorName = notification.actor?.username ?? 'Someone';
    final description = notification.getDescription();
    final timestamp = _formatTimestamp(notification.createdAt);
    final icon = _getNotificationIcon(notification.type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Icon
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _getNotificationColor(brightness).withValues(alpha: 0.1),
                borderRadius: ORARadius.smallAll,
              ),
              child: Icon(
                icon,
                size: 14,
                color: _getNotificationColor(brightness),
              ),
            ),
            const SizedBox(width: ORASpacing.xs),
            // Display name
            Expanded(
              child: Text(
                actorName,
                style: ORATypography.label(context).copyWith(
                  fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                  color: ORAColors.textPrimary(brightness),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: ORASpacing.xs),
        // Description
        Text(
          description,
          style: ORATypography.body(context).copyWith(
            color: ORAColors.textSecondary(brightness),
            fontSize: 14,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: ORASpacing.xs),
        // Timestamp
        Text(
          timestamp,
          style: ORATypography.caption(context).copyWith(
            color: ORAColors.textTertiary(brightness),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildUnreadIndicator(Brightness brightness) {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(left: ORASpacing.sm, top: 4),
      decoration: BoxDecoration(
        color: ORAColors.primary(brightness),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildSwipeBackground(
    BuildContext context,
    Brightness brightness, {
    required bool isLeftSwipe,
  }) {
    final color = isLeftSwipe ? Colors.red : ORAColors.primary(brightness);
    final icon = isLeftSwipe ? Icons.delete_outline : Icons.check_circle_outline;
    final label = isLeftSwipe ? 'Delete' : 'Mark read';

    return Container(
      alignment: isLeftSwipe ? Alignment.centerRight : Alignment.centerLeft,
      padding: EdgeInsets.symmetric(
        horizontal: ORASpacing.lg,
        vertical: ORASpacing.md,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: ORARadius.mediumAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(width: ORASpacing.sm),
          Text(
            label,
            style: ORATypography.label(context).copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.like:
        return Icons.favorite_rounded;
      case NotificationType.comment:
        return Icons.comment_rounded;
      case NotificationType.reply:
        return Icons.reply_rounded;
      case NotificationType.follow:
        return Icons.person_add_rounded;
    }
  }

  Color _getNotificationColor(Brightness brightness) {
    switch (notification.type) {
      case NotificationType.like:
        return Colors.red;
      case NotificationType.comment:
        return ORAColors.primary(brightness);
      case NotificationType.reply:
        return Colors.blue;
      case NotificationType.follow:
        return Colors.green;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}