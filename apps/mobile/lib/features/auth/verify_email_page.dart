import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/backend/supabase_client.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/core/theme/ora_spacing.dart';
import 'package:mobile/core/theme/ora_typography.dart';
import 'package:mobile/features/session/session_provider.dart';
import 'package:mobile/shared/widgets/ora_button.dart';

/// ORA Verify Email Page
///
/// Shown after signup when email confirmation is required.
/// Allows the user to resend the verification email with a cooldown timer.
/// Automatically detects when the user has verified their email and
/// navigates to the home screen.
class VerifyEmailPage extends ConsumerStatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;
  bool _isSending = false;
  String? _errorMessage;
  String? _successMessage;

  static const int _cooldownDuration = 60;

  @override
  void initState() {
    super.initState();
    _startCooldown();
    _checkVerificationStatus();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  /// Starts the resend cooldown timer.
  void _startCooldown() {
    _cooldownSeconds = _cooldownDuration;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds <= 0) {
        timer.cancel();
        if (mounted) setState(() {});
        return;
      }
      setState(() => _cooldownSeconds--);
    });
  }

  /// Periodically checks if the user has verified their email.
  /// When verified, navigates to home.
  void _checkVerificationStatus() {
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (!SupabaseClientProvider.isInitialized) {
        timer.cancel();
        return;
      }

      final user = SupabaseClientProvider.client!.auth.currentUser;
      if (user != null && user.emailConfirmedAt != null) {
        timer.cancel();
        if (mounted) {
          context.go('/home');
        }
      }
    });
  }

  /// Resends the verification email.
  Future<void> _resendVerification() async {
    if (_cooldownSeconds > 0 || _isSending) return;

    setState(() {
      _isSending = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final success = await ref
          .read(sessionProvider.notifier)
          .resendVerification();

      if (mounted) {
        if (success) {
          setState(() {
            _successMessage = 'Verification email sent. Check your inbox.';
          });
          _startCooldown();
        } else {
          setState(() {
            _errorMessage = 'Could not send verification email.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to send verification email. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
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
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon
              Icon(
                Icons.mark_email_read_outlined,
                size: 80,
                color: ORAColors.primary(brightness),
              ),
              const SizedBox(height: ORASpacing.xxl),

              // Title
              Text(
                'Verify Your Email',
                textAlign: TextAlign.center,
                style: ORATypography.heading(context).copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: ORASpacing.md),

              // Description
              Text(
                'We sent a verification link to your email. '
                'Click the link to activate your account.',
                textAlign: TextAlign.center,
                style: ORATypography.body(context).copyWith(
                  color: ORAColors.textSecondary(brightness),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: ORASpacing.xxl),

              // Success message
              if (_successMessage != null) ...[
                Text(
                  _successMessage!,
                  textAlign: TextAlign.center,
                  style: ORATypography.body(context).copyWith(
                    color: ORAColors.success(brightness),
                  ),
                ),
                const SizedBox(height: ORASpacing.lg),
              ],

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

              // Resend button
              ORAButton(
                text: _cooldownSeconds > 0
                    ? 'Resend in ${_cooldownSeconds}s'
                    : 'Resend Verification Email',
                onPressed: _cooldownSeconds > 0 ? null : _resendVerification,
                isLoading: _isSending,
              ),
              const SizedBox(height: ORASpacing.lg),

              // Back to login
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text(
                  'Back to Login',
                  style: ORATypography.body(context).copyWith(
                    color: ORAColors.primary(brightness),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}