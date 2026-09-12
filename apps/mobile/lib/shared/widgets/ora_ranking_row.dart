import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile/core/theme/ora_animations.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/core/theme/ora_radius.dart';
import 'package:mobile/core/theme/ora_spacing.dart';
import 'package:mobile/core/theme/ora_typography.dart';
import 'package:mobile/shared/widgets/ora_avatar.dart';
import 'package:mobile/shared/widgets/ora_badge.dart';

/// ORA Design System — Reusable Ranking Row
///
/// Shared leaderboard row used by the Leaderboard Page and Hood leaderboard.
class ORARankingRow extends StatelessWidget {
  final int rank;
  final String avatarLetter;
  final List<Color> avatarColors;
  final String username;
  final int auraPoints;
  final bool isCurrentUser;
  final int? steezeLevel;
  final String? prestigeBadge;
  final bool animate;

  const ORARankingRow({
    super.key,
    required this.rank,
    required this.avatarLetter,
    required this.avatarColors,
    required this.username,
    required this.auraPoints,
    this.isCurrentUser = false,
    this.steezeLevel,
    this.prestigeBadge,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    final row = Container(
      margin: const EdgeInsets.only(bottom: ORASpacing.md),
      padding: const EdgeInsets.all(ORASpacing.md),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? ORAColors.primary(brightness).withValues(alpha: 0.08)
            : ORAColors.surface(brightness),
        borderRadius: ORARadius.mediumAll,
        border: Border.all(
          color: isCurrentUser
              ? ORAColors.primary(brightness).withValues(alpha: 0.2)
              : ORAColors.border(brightness),
        ),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? ORAColors.accent(brightness).withValues(alpha: 0.2)
                  : ORAColors.surface(brightness).withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: ORATypography.caption(context).copyWith(
                  color: rank <= 3
                      ? ORAColors.accent(brightness)
                      : ORAColors.textSecondary(brightness),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: ORASpacing.md),
          // Avatar
          ORAAvatar(
            letter: avatarLetter,
            size: 40,
            gradientColors: avatarColors,
          ),
          const SizedBox(width: ORASpacing.md),
          // Username + Steeze
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      username,
                      style: ORATypography.label(context).copyWith(
                        color: ORAColors.textPrimary(brightness),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (prestigeBadge != null) ...[
                      const SizedBox(width: ORASpacing.sm),
                      ORABadge(
                        text: prestigeBadge!,
                        color: ORAColors.accent(brightness),
                        fontSize: 10,
                      ),
                    ],
                  ],
                ),
                if (steezeLevel != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.trending_up_rounded,
                        color: ORAColors.textTertiary(brightness),
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'Lvl $steezeLevel',
                        style: ORATypography.caption(context),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Aura Points
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ORASpacing.md,
              vertical: ORASpacing.sm,
            ),
            decoration: BoxDecoration(
              color: ORAColors.primary(brightness).withValues(alpha: 0.15),
              borderRadius: ORARadius.mediumAll,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: ORAColors.primary(brightness),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '$auraPoints',
                  style: ORATypography.label(context).copyWith(
                    color: ORAColors.primary(brightness),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!animate) return row;

    return row
        .animate()
        .fadeIn(duration: ORAAnimations.fast, delay: ORAAnimations.fast)
        .slideY(
          begin: 0.05,
          end: 0,
          duration: ORAAnimations.fast,
          curve: Curves.easeOut,
        );
  }
}