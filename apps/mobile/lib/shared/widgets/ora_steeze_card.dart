import 'package:flutter/material.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/core/theme/ora_radius.dart';
import 'package:mobile/core/theme/ora_spacing.dart';
import 'package:mobile/core/theme/ora_typography.dart';
import 'package:mobile/shared/widgets/ora_card.dart';

/// ORA Design System — Reusable Steeze Card
///
/// Shared Steeze/level progression card used by the Aura Page and Profile Page.
class ORASteezeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String levelChipText;
  final double progress;
  final String leftLabel;
  final String rightLabel;
  final List<Color> gradientColors;

  const ORASteezeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.levelChipText,
    required this.progress,
    required this.leftLabel,
    required this.rightLabel,
    this.gradientColors = const [],
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final colors = gradientColors.isNotEmpty
        ? gradientColors
        : <Color>[
            ORAColors.accent(brightness),
            ORAColors.accent(brightness).withValues(alpha: 0.7),
          ];

    return ORACard(
      padding: const EdgeInsets.all(ORASpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: ORAColors.accent(brightness),
                    size: 24,
                  ),
                  const SizedBox(width: ORASpacing.sm),
                  Text(
                    title,
                    style: ORATypography.title(context),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ORASpacing.md,
                  vertical: ORASpacing.sm,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                  ),
                  borderRadius: ORARadius.mediumAll,
                ),
                child: Text(
                  levelChipText,
                  style: ORATypography.label(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ORASpacing.md),
          // Progress bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: ORAColors.surface(brightness).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              widthFactor: progress,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: ORASpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                leftLabel,
                style: ORATypography.caption(context),
              ),
              Text(
                rightLabel,
                style: ORATypography.caption(context).copyWith(
                  color: ORAColors.textSecondary(brightness),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}