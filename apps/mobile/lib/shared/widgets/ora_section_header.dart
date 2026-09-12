import 'package:flutter/material.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/core/theme/ora_spacing.dart';
import 'package:mobile/core/theme/ora_typography.dart';

/// ORA Design System — Reusable Section Header
///
/// Shared section title with optional subtitle and trailing widget.
class ORASectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const ORASectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: ORATypography.title(context),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: ORASpacing.xs),
                Text(
                  subtitle!,
                  style: ORATypography.caption(context).copyWith(
                    color: ORAColors.textSecondary(brightness),
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing ?? const SizedBox.shrink(),
      ],
    );
  }
}