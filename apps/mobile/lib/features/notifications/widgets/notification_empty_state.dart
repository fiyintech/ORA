import 'package:flutter/material.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/core/theme/ora_spacing.dart';
import 'package:mobile/core/theme/ora_typography.dart';
import 'package:mobile/shared/widgets/ora_empty_state.dart';

/// ORA Design System — Notification Empty State
///
/// Displays when there are no notifications.
/// Reuses the ORAEmptyState component for consistency.
class NotificationEmptyState extends StatelessWidget {
  const NotificationEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return ORAEmptyState(
      title: 'No notifications yet',
      description: 'We\'ll let you know when something happens.',
      icon: Icons.notifications_outlined,
    );
  }
}
