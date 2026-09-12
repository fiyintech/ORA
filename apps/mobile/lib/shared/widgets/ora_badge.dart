import 'package:flutter/material.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/core/theme/ora_radius.dart';

/// ORA Design System — Reusable Badge
///
/// Displays a small label/tag. Supports both dark and light themes automatically.
class ORABadge extends StatelessWidget {
  final String text;
  final Color? color;
  final Color? textColor;
  final double fontSize;

  const ORABadge({
    super.key,
    required this.text,
    this.color,
    this.textColor,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bgColor = (color ?? ORAColors.primary(brightness)).withValues(alpha: 0.2);
    final fgColor = textColor ?? color ?? ORAColors.primary(brightness);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: ORARadius.smallAll,
        border: Border.all(
          color: fgColor,
          width: 0.5,
        ),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: fgColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}