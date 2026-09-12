import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/core/theme/ora_spacing.dart';
import 'package:mobile/core/theme/ora_typography.dart';
import 'package:mobile/features/session/session_provider.dart';
import 'package:mobile/shared/widgets/ora_button.dart';
import 'package:mobile/shared/widgets/ora_text_field.dart';

/// ORA Change Password Page
///
/// Allows an authenticated user to update their password securely.
/// Validates the new password and shows friendly error messages.
class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isSuccess = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validation
    if (currentPassword.isEmpty) {
      setState(() => _errorMessage = 'Please enter your current password.');
      return;
    }

    if (newPassword.isEmpty) {
      setState(() => _errorMessage = 'Please enter a new password.');
      return;
    }

    if (newPassword.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters.');
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Reauthenticate first for security
      final reauthSuccess = await ref
          .read(sessionProvider.notifier)
          .reauthenticate(currentPassword);

      if (!reauthSuccess) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Reauthentication failed. Please try again.';
          });
        }
        return;
      }

      final success = await ref
          .read(sessionProvider.notifier)
          .updatePassword(newPassword);

      if (mounted) {
        if (success) {
          setState(() => _isSuccess = true);
        } else {
          setState(() {
            _errorMessage = 'Could not update password. Please try again.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to update password. Please try again.';
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
      appBar: AppBar(
        backgroundColor: ORAColors.background(brightness),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Change Password',
          style: ORATypography.title(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(ORASpacing.xxl),
          child: _isSuccess
              ? _buildSuccessState(context, brightness)
              : _buildForm(context, brightness),
        ),
      ),
    );
  }

  Widget _buildSuccessState(BuildContext context, Brightness brightness) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 64,
          color: ORAColors.success(brightness),
        ),
        const SizedBox(height: ORASpacing.lg),
        Text(
          'Password Updated!',
          textAlign: TextAlign.center,
          style: ORATypography.heading(context).copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: ORASpacing.sm),
        Text(
          'Your password has been changed successfully.',
          textAlign: TextAlign.center,
          style: ORATypography.body(context).copyWith(
            color: ORAColors.textSecondary(brightness),
          ),
        ),
        const SizedBox(height: ORASpacing.xxl),
        ORAButton(
          text: 'Back to Profile',
          onPressed: () => context.go('/profile'),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: ORASpacing.lg),

        // Current password
        ORATextField(
          label: 'Current Password',
          hintText: 'Enter your current password',
          controller: _currentPasswordController,
          isPassword: true,
          enabled: !_isLoading,
        ),
        const SizedBox(height: ORASpacing.lg),

        // New password
        ORATextField(
          label: 'New Password',
          hintText: 'Create a new password',
          controller: _newPasswordController,
          isPassword: true,
          enabled: !_isLoading,
        ),
        const SizedBox(height: ORASpacing.lg),

        // Confirm new password
        ORATextField(
          label: 'Confirm New Password',
          hintText: 'Confirm your new password',
          controller: _confirmPasswordController,
          isPassword: true,
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

        // Update button
        ORAButton(
          text: 'Update Password',
          onPressed: _isLoading ? null : _changePassword,
          isLoading: _isLoading,
        ),
      ],
    );
  }
}