import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/core/theme/ora_spacing.dart';
import 'package:mobile/core/theme/ora_typography.dart';
import 'package:mobile/features/session/session_provider.dart';
import 'package:mobile/shared/widgets/ora_button.dart';
import 'package:mobile/shared/widgets/ora_text_field.dart';

/// ORA Forgot Password Page
///
/// Allows the user to request a password reset email.
/// Shows success/error states and a link back to login.
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email address.');
      return;
    }

    if (!email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await ref
          .read(sessionProvider.notifier)
          .sendPasswordReset(email);

      if (mounted) {
        if (success) {
          setState(() => _isSent = true);
        } else {
          setState(() {
            _errorMessage = 'Could not send reset email. Please try again.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to send reset email. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: ORAColors.background(brightness),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(ORASpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: ORASpacing.xxl),

              // Title
              Text(
                'Forgot Password',
                textAlign: TextAlign.center,
                style: ORATypography.heading(context).copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: ORASpacing.md),

              // Description
              Text(
                'Enter your email and we\'ll send you a link to reset your password.',
                textAlign: TextAlign.center,
                style: ORATypography.body(context).copyWith(
                  color: ORAColors.textSecondary(brightness),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: ORASpacing.xxl),

              // Success state
              if (_isSent) ...[
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: ORAColors.success(brightness),
                ),
                const SizedBox(height: ORASpacing.lg),
                Text(
                  'Reset email sent!',
                  textAlign: TextAlign.center,
                  style: ORATypography.heading(context).copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: ORASpacing.sm),
                Text(
                  'Check your inbox for a link to reset your password.',
                  textAlign: TextAlign.center,
                  style: ORATypography.body(context).copyWith(
                    color: ORAColors.textSecondary(brightness),
                  ),
                ),
                const SizedBox(height: ORASpacing.xxl),
                ORAButton(
                  text: 'Back to Login',
                  onPressed: () => context.go('/login'),
                ),
              ] else ...[
                // Email field
                ORATextField(
                  label: 'Email',
                  hintText: 'Enter your email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: ORASpacing.lg),

                // Error message
                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: ORATypography.body(context).copyWith(
                      color: ORAColors.error(brightness),
                    ),
                  ),
                  const SizedBox(height: ORASpacing.lg),
                ],

                // Send button
                ORAButton(
                  text: 'Send Reset Email',
                  onPressed: _isLoading ? null : _sendResetEmail,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: ORASpacing.lg),

                // Back to login
                TextButton(
                  onPressed: _isLoading ? null : () => context.go('/login'),
                  child: Text(
                    'Back to Login',
                    style: ORATypography.body(context).copyWith(
                      color: ORAColors.primary(brightness),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}