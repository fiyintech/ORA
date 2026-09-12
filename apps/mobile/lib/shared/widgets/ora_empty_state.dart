import 'package:flutter/material.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/core/theme/ora_spacing.dart';
import 'package:mobile/core/theme/ora_typography.dart';
import 'package:mobile/shared/widgets/ora_button.dart';

/// ORA Design System — Reusable Empty State
///
/// Shared empty/placeholder layout used across the app.
/// Supports an optional primary action button.
class ORAEmptyState extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const ORAEmptyState({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ORASpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon in a gradient circular container
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ORAColors.primary(brightness).withValues(alpha: 0.15),
                    ORAColors.secondary(brightness).withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: ORAColors.primary(brightness).withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                size: 40,
                color: ORAColors.primary(brightness),
              ),
            ),
            const SizedBox(height: ORASpacing.lg),
            // Title
            Text(
              title,
              style: ORATypography.title(context).copyWith(
                color: ORAColors.textPrimary(brightness),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ORASpacing.sm),
            // Description
            Text(
              description,
              style: ORATypography.body(context).copyWith(
                color: ORAColors.textSecondary(brightness),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            // Optional primary action
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: ORASpacing.xl),
              ORAButton(
                text: buttonText!,
                onPressed: onButtonPressed,
                isFullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
