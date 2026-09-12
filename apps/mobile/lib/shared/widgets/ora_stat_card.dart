import 'package:flutter/material.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/core/theme/ora_spacing.dart';
import 'package:mobile/core/theme/ora_typography.dart';
import 'package:mobile/shared/widgets/ora_card.dart';

/// ORA Design System — Reusable Stat Card
///
/// Single statistics tile with icon, value and label.
class ORAStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const ORAStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return ORACard(
      padding: const EdgeInsets.all(ORASpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: ORAColors.primary(brightness),
            size: 24,
          ),
          const SizedBox(height: ORASpacing.sm),
          Text(
            value,
            style: ORATypography.title(context).copyWith(
              fontSize: 20,
              color: ORAColors.textPrimary(brightness),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: ORATypography.caption(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}