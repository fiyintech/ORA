import 'package:flutter/material.dart';
import 'package:mobile/core/theme/ora_colors.dart';

/// ORA Design System — Reusable Loading Indicator
///
/// Supports both dark and light themes automatically.
class ORALoadingIndicator extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;

  const ORALoadingIndicator({
    super.key,
    this.size = 32,
    this.strokeWidth = 3,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final indicatorColor = color ?? ORAColors.primary(brightness);

    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
      ),
    );
  }
}