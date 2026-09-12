import 'package:flutter/material.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/core/theme/ora_radius.dart';
import 'package:mobile/core/theme/ora_shadows.dart';

/// ORA Design System — Reusable Card
///
/// Supports both dark and light themes automatically.
class ORACard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const ORACard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    final card = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ORAColors.card(brightness),
        borderRadius: ORARadius.largeAll,
        border: Border.all(color: ORAColors.border(brightness)),
        boxShadow: ORAShadows.small,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}