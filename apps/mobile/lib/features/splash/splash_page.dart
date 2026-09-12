import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/core/theme/ora_spacing.dart';
import 'package:mobile/shared/widgets/ora_loading_indicator.dart';

/// ORA Splash Screen
///
/// Displays the ORA brand with a polished entrance animation.
/// NOTE: The circular placeholder below is temporary — swap in the
/// official ORA logo asset here when it becomes available.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ORAColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            // Logo mark
            _buildLogoMark(),
            const SizedBox(height: ORASpacing.xxl),
            // ORA wordmark
            const Text(
              'ORA',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: ORAColors.darkPrimary,
                letterSpacing: 2,
              ),
            ).animate().fadeIn(duration: 600.ms).scale(
                  begin: const Offset(0.92, 0.92),
                  end: const Offset(1.0, 1.0),
                  duration: 600.ms,
                  curve: Curves.easeOut,
                ),
            const SizedBox(height: ORASpacing.md),
            // Tagline
            const Text(
              'Built on Reputation.',
              style: TextStyle(
                fontSize: 16,
                color: ORAColors.darkTextSecondary,
                letterSpacing: 0.5,
              ),
            ).animate().fadeIn(
                  delay: 200.ms,
                  duration: 600.ms,
                ),
            const Spacer(flex: 2),
            // Subtle loading indicator
            const ORALoadingIndicator(
              size: 24,
              strokeWidth: 2,
              color: ORAColors.darkPrimary,
            ).animate().fadeIn(
                  delay: 400.ms,
                  duration: 400.ms,
                ),
            const SizedBox(height: ORASpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoMark() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ORAColors.darkPrimary,
            ORAColors.darkSecondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: ORAColors.darkPrimary.withValues(alpha: 0.4),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'O',
          style: TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          duration: 500.ms,
          curve: Curves.easeOutBack,
        );
  }
}