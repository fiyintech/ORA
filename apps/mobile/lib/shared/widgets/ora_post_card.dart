import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile/core/theme/ora_animations.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/core/theme/ora_radius.dart';
import 'package:mobile/core/theme/ora_spacing.dart';
import 'package:mobile/core/theme/ora_typography.dart';
import 'package:mobile/shared/widgets/ora_avatar.dart';
import 'package:mobile/shared/widgets/ora_badge.dart';
import 'package:mobile/shared/widgets/ora_card.dart';

/// ORA Design System — Reusable Post Card
///
/// Shared feed post layout used by the Home feed and Hood feed.
/// Presentation-only; callers supply the rendered values.
class ORAPostCard extends StatelessWidget {
  final String avatarLetter;
  final List<Color> avatarGradientColors;
  final String username;
  final String time;
  final String content;
  final Widget? media;
  final bool showSyncingBadge;
  final bool showVisibilityBadge;
  final String? visibilityLabel;
  final Widget? usernameTrailing;
  final Widget? avatarBadge;
  final Widget contentTrailing;
  final List<Widget> footerActions;
  final bool animate;

  const ORAPostCard({
    super.key,
    required this.avatarLetter,
    required this.avatarGradientColors,
    required this.username,
    required this.time,
    required this.content,
    this.media,
    this.showSyncingBadge = false,
    this.showVisibilityBadge = false,
    this.visibilityLabel,
    this.usernameTrailing,
    this.avatarBadge,
    this.contentTrailing = const SizedBox.shrink(),
    this.footerActions = const [],
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    final card = ORACard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(ORASpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar + Username + Time + Badges
          Row(
            children: [
              ORAAvatar(
                letter: avatarLetter,
                size: 40,
                gradientColors: avatarGradientColors,
              ),
              const SizedBox(width: ORASpacing.md),
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
                        if (showSyncingBadge) ...[
                          const SizedBox(width: ORASpacing.sm),
                          ORABadge(
                            text: 'SYNCING',
                            color: ORAColors.accent(brightness),
                            fontSize: 9,
                          ),
                        ],
                        if (usernameTrailing != null) ...[
                          const SizedBox(width: ORASpacing.sm),
                          usernameTrailing!,
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      time,
                      style: ORATypography.caption(context),
                    ),
                  ],
                ),
              ),
              if (showVisibilityBadge)
                ORABadge(
                  text: visibilityLabel ?? 'Friends',
                  color: ORAColors.primary(brightness),
                  fontSize: 10,
                ),
            ],
          ),
          const SizedBox(height: ORASpacing.md),
          // Post text
          Text(
            content,
            style: ORATypography.body(context).copyWith(
              color: ORAColors.textPrimary(brightness),
              height: 1.5,
            ),
          ),
          // Post image (if available)
          if (media != null) ...[
            const SizedBox(height: ORASpacing.md),
            ClipRRect(
              borderRadius: ORARadius.mediumAll,
              child: media,
            ),
          ],
          const SizedBox(height: ORASpacing.lg),
          // Action buttons
          Row(
            children: footerActions,
          ),
          contentTrailing,
        ],
      ),
    );

    if (!animate) return card;

    return card
        .animate()
        .fadeIn(duration: ORAAnimations.normal, delay: ORAAnimations.normal)
        .slideY(
          begin: 0.1,
          end: 0,
          duration: ORAAnimations.normal,
          delay: ORAAnimations.normal,
          curve: Curves.easeOut,
        );
  }
}