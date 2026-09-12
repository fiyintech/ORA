import 'package:flutter/material.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/core/theme/ora_typography.dart';

class PlaceholderPage extends StatelessWidget {
  final String title;
  final IconData icon;

  const PlaceholderPage({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: ORAColors.background(brightness),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: ORAColors.primary(brightness).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: ORAColors.primary(brightness), // Royal Purple
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: ORATypography.heading(context),
            ),
            const SizedBox(height: 12),
            Text(
              'Coming Soon',
              style: ORATypography.body(context).copyWith(
                color: ORAColors.textSecondary(brightness),
              ),
            ),
          ],
        ),
      ),
    );
  }
}