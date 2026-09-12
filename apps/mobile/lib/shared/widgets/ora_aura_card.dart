import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile/core/theme/ora_animations.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/core/theme/ora_spacing.dart';
import 'package:mobile/core/theme/ora_typography.dart';
import 'package:mobile/shared/widgets/ora_card.dart';

/// ORA Design System — Reusable Aura Card
///
/// Shared Aura summary card used by the Aura Page and Profile Page.
class ORAAuraCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String auraValue;
  final double valueFontSize;
  final bool animate;
  final Widget? bottom;

  const ORAAuraCard({
    super.key,
    required this.title,
    required this.icon,
    required this.auraValue,
    this.valueFontSize = 48,
    this.animate = true,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    final aura = ORACard(
      padding: const EdgeInsets.all(ORASpacing.xl),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: ORAColors.accent(brightness),
                size: 28,
              ),
              const SizedBox(width: ORASpacing.sm),
              Text(
                title,
                style: ORATypography.title(context),
              ),
            ],
          ),
          const SizedBox(height: ORASpacing.md),
          Text(
            auraValue,
            style: ORATypography.display(context).copyWith(
              color: ORAColors.accent(brightness),
              fontSize: valueFontSize,
            ),
          ),
          if (bottom != null) ...[
            const SizedBox(height: ORASpacing.md),
            bottom!,
          ],
        ],
      ),
    );

    if (!animate) return aura;

    return aura.animate().fadeIn(duration: ORAAnimations.slow, delay: ORAAnimations.normal);
  }
}