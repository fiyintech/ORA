import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/core/theme/ora_spacing.dart';
import 'package:mobile/core/theme/ora_typography.dart';
import 'package:mobile/shared/widgets/ora_button.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: ORAColors.background(brightness),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(ORASpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ORA Logo mark
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ORAColors.primary(brightness),
                        ORAColors.secondary(brightness),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: ORAColors.primary(brightness).withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'O',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: ORASpacing.xxxl),
              // ORA wordmark
              Text(
                'ORA',
                textAlign: TextAlign.center,
                style: ORATypography.display(context).copyWith(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: ORAColors.primary(brightness),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: ORASpacing.xxl),
              // Welcome back text
              Text(
                'Welcome back.',
                textAlign: TextAlign.center,
                style: ORATypography.heading(context).copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: ORASpacing.md),
              // Tagline
              Text(
                'Your reputation starts here.',
                textAlign: TextAlign.center,
                style: ORATypography.body(context).copyWith(
                  fontSize: 16,
                  color: ORAColors.textSecondary(brightness),
                ),
              ),
              const SizedBox(height: ORASpacing.huge),
              // Login button
              ORAButton(
                text: 'Login',
                onPressed: () {
                  context.push("/login");
                },
              ),
              const SizedBox(height: 16),
              // Create Account button
              ORAButton(
                text: 'Create Account',
                isPrimary: false,
                onPressed: () {
                  context.push("/signup");
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}