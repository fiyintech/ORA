import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/core/theme/ora_spacing.dart';
import 'package:mobile/core/theme/ora_typography.dart';
import 'package:mobile/features/session/session_provider.dart';
import 'package:mobile/shared/widgets/ora_button.dart';
import 'package:mobile/shared/widgets/ora_text_field.dart';

/// ORA Change Email Page
///
/// Allows an authenticated user to update their email address.
/// Requires reauthentication with the current password for security.
/// Shows success/error states and updates the cached profile.
class ChangeEmailPage extends ConsumerStatefulWidget {
  const ChangeEmailPage({super.key});

  @override
  ConsumerState<ChangeEmailPage> createState() => _ChangeEmailPageState();
}

class _ChangeEmailPageState extends ConsumerState<ChangeEmailPage> {
  final _currentPasswordController = TextEditingController();
  final _newEmailController = TextEditingController();
  bool _isLoading = false;
  bool _isSuccess = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newEmailController.dispose();
    super.dispose();
  }

  Future<void> _changeEmail() async {
    final currentPassword = _currentPasswordController.text;
    final newEmail = _newEmailController.text.trim();

    // Validation
    if (currentPassword.isEmpty) {
      setState(() => _errorMessage = 'Please enter your current password.');
      return;
    }

    if (newEmail.isEmpty) {
      setState(() => _errorMessage = 'Please enter your new email.');
      return;
    }

    if (!newEmail.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
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
          .updateEmail(newEmail);

      if (mounted) {
        if (success) {
          setState(() => _isSuccess = true);
        } else {
          setState(() {
            _errorMessage = 'Could not update email. Please try again.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to update email. Please try again.';
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
          'Change Email',
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
          'Email Updated!',
          textAlign: TextAlign.center,
          style: ORATypography.heading(context).copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: ORASpacing.sm),
        Text(
          'Your email has been changed. '
          'You may need to verify the new email address.',
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

        // Current password (for reauthentication)
        ORATextField(
          label: 'Current Password',
          hintText: 'Enter your current password',
          controller: _currentPasswordController,
          isPassword: true,
          enabled: !_isLoading,
        ),
        const SizedBox(height: ORASpacing.lg),

        // New email
        ORATextField(
          label: 'New Email',
          hintText: 'Enter your new email',
          controller: _newEmailController,
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

        // Update button
        ORAButton(
          text: 'Update Email',
          onPressed: _isLoading ? null : _changeEmail,
          isLoading: _isLoading,
        ),
      ],
    );
  }
}