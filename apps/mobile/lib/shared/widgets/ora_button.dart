import 'package:flutter/material.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/core/theme/ora_radius.dart';
import 'package:mobile/core/theme/ora_spacing.dart';
import 'package:mobile/core/theme/ora_typography.dart';

/// ORA Design System — Reusable Button
///
/// Supports both dark and light themes automatically.
class ORAButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isLoading;
  final bool isFullWidth;

  const ORAButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isPrimary = true,
    this.isLoading = false,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final backgroundColor = isPrimary
        ? ORAColors.primary(brightness)
        : ORAColors.surface(brightness);
    final foregroundColor = isPrimary
        ? Colors.white
        : ORAColors.textPrimary(brightness);
    final borderColor = isPrimary ? null : ORAColors.border(brightness);

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: backgroundColor.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: ORARadius.largeAll,
            side: borderColor != null
                ? BorderSide(color: borderColor)
                : BorderSide.none,
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: ORASpacing.xxl,
            vertical: ORASpacing.lg,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                ),
              )
            : Text(text, style: ORATypography.title(context)),
      ),
    );
  }
}