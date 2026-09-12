import 'package:flutter/material.dart';
import 'package:mobile/core/models/notification.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/core/theme/ora_spacing.dart';
import 'package:mobile/core/theme/ora_typography.dart';

/// ORA Design System — Notification Group
///
/// Groups notifications by time period (Today, Yesterday, Earlier, etc.)
/// Only shows the group header if there are notifications in that group.
class NotificationGroup extends StatelessWidget {
  final String title;
  final List<NotificationModel> notifications;
  final Widget Function(NotificationModel) itemBuilder;

  const NotificationGroup({
    super.key,
    required this.title,
    required this.notifications,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return const SizedBox.shrink();
    }

    final brightness = Theme.of(context).brightness;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group header
        Padding(
          padding: const EdgeInsets.only(
            left: ORASpacing.lg,
            right: ORASpacing.lg,
            top: ORASpacing.lg,
            bottom: ORASpacing.sm,
          ),
          child: Text(
            title,
            style: ORATypography.label(context).copyWith(
              color: ORAColors.textSecondary(brightness),
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ),
        // Notifications
        ...notifications.map(itemBuilder).toList(),
      ],
    );
  }
}

/// Helper class to group notifications by time period.
class NotificationGrouper {
  static List<GroupedNotifications> group(List<NotificationModel> notifications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final newNotifications = <NotificationModel>[];
    final todayNotifications = <NotificationModel>[];
    final yesterdayNotifications = <NotificationModel>[];
    final earlierNotifications = <NotificationModel>[];

    for (final notification in notifications) {
      final notificationDate = DateTime(
        notification.createdAt.year,
        notification.createdAt.month,
        notification.createdAt.day,
      );

      if (notificationDate == today) {
        todayNotifications.add(notification);
      } else if (notificationDate == yesterday) {
        yesterdayNotifications.add(notification);
      } else if (notification.createdAt.isAfter(today.subtract(const Duration(days: 7)))) {
        earlierNotifications.add(notification);
      } else {
        newNotifications.add(notification);
      }
    }

    final groups = <GroupedNotifications>[];

    if (newNotifications.isNotEmpty) {
      groups.add(GroupedNotifications(
        title: 'New',
        notifications: newNotifications,
      ));
    }

    if (todayNotifications.isNotEmpty) {
      groups.add(GroupedNotifications(
        title: 'Today',
        notifications: todayNotifications,
      ));
    }

    if (yesterdayNotifications.isNotEmpty) {
      groups.add(GroupedNotifications(
        title: 'Yesterday',
        notifications: yesterdayNotifications,
      ));
    }

    if (earlierNotifications.isNotEmpty) {
      groups.add(GroupedNotifications(
        title: 'Earlier',
        notifications: earlierNotifications,
      ));
    }

    return groups;
  }
}

/// Represents a group of notifications with a title.
class GroupedNotifications {
  final String title;
  final List<NotificationModel> notifications;

  const GroupedNotifications({
    required this.title,
    required this.notifications,
  });
}
