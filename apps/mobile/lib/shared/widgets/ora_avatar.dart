import 'package:flutter/material.dart';
import 'package:mobile/core/theme/ora_colors.dart';

/// ORA Design System — Reusable Avatar
///
/// Displays a circular avatar with gradient background and letter.
/// Supports both dark and light themes automatically.
class ORAAvatar extends StatelessWidget {
  final String letter;
  final double size;
  final List<Color>? gradientColors;
  final String? imageUrl;

  const ORAAvatar({
    super.key,
    required this.letter,
    this.size = 40,
    this.gradientColors,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ??
        [
          ORAColors.primary(Theme.of(context).brightness),
          ORAColors.secondary(Theme.of(context).brightness),
        ];

    final displayLetter = letter.isNotEmpty ? letter[0].toUpperCase() : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          displayLetter,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.45,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}