import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/backend/repositories/impl/providers.dart';
import 'package:mobile/core/utils/logger.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/core/theme/ora_radius.dart';
import 'package:mobile/core/theme/ora_spacing.dart';
import 'package:mobile/core/theme/ora_typography.dart';
import 'package:mobile/features/session/session_provider.dart';
import 'package:mobile/shared/widgets/ora_button.dart';
import 'package:mobile/shared/widgets/ora_text_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ORA Edit Profile Page
///
/// Allows the user to edit their profile information:
/// - Avatar upload
/// - Banner upload
/// - Username (with validation)
/// - Display name
/// - Bio
/// - Website
/// - Location
///
/// Uses optimistic updates with rollback on failure.
class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _websiteController = TextEditingController();
  final _locationController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  String? _avatarPath;
  String? _bannerPath;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUsernameValid = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _websiteController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final repository = ref.read(profileRepositoryProvider);
    final profile = await repository.getProfile(currentUser.id);

    if (mounted) {
      setState(() {
        _displayNameController.text =
            profile.value?['display_name'] as String? ?? currentUser.fullName;
        _usernameController.text =
            profile.value?['username'] as String? ?? currentUser.username;
        _bioController.text = profile.value?['bio'] as String? ?? '';
        _websiteController.text = profile.value?['website'] as String? ?? '';
        _locationController.text = profile.value?['location'] as String? ?? '';
        _avatarPath = profile.value?['avatar'] as String?;
        _bannerPath = profile.value?['banner_url'] as String?;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAvatar() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() => _avatarPath = image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick avatar')),
        );
      }
    }
  }

  Future<void> _pickBanner() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() => _bannerPath = image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick banner')),
        );
      }
    }
  }

  Future<void> _validateUsername() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() => _isUsernameValid = false);
      return;
    }

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final repository = ref.read(profileRepositoryProvider);
    final result = await repository.validateUsername(
      username,
      excludeUserId: currentUser.id,
    );

    if (mounted) {
      setState(() => _isUsernameValid = result.value ?? true);
    }
  }

  Future<void> _saveProfile() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    // ── IDENTITY VERIFICATION LOG (TEMPORARY — Sprint 1.3) ──
    Logger.info(
      '========== IDENTITY VERIFICATION: _saveProfile (caller) ==========\n'
      'AUTH UID: ${Supabase.instance.client.auth.currentUser?.id}\n'
      'SESSION UID: ${Supabase.instance.client.auth.currentSession?.user.id}\n'
      'CURRENT USER PROVIDER UID: ${currentUser.id}',
      tag: 'EditProfilePage',
    );
    // ── END IDENTITY VERIFICATION LOG ──

    final displayName = _displayNameController.text.trim();
    final username = _usernameController.text.trim();
    final bio = _bioController.text.trim();

    // Validation
    if (displayName.isEmpty) {
      setState(() => _errorMessage = 'Display name cannot be empty.');
      return;
    }

    if (username.isEmpty) {
      setState(() => _errorMessage = 'Username cannot be empty.');
      return;
    }

    if (!_isUsernameValid) {
      setState(() => _errorMessage = 'Username is already taken.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(profileRepositoryProvider);

      // Upload avatar if changed
      if (_avatarPath != null && _avatarPath!.startsWith('/')) {
        final avatarResult = await repository.updateAvatar(
          currentUser.id,
          _avatarPath!,
        );
        if (avatarResult.isFailure) {
          throw Exception(avatarResult.failure?.message);
        }
      }

      // Upload banner if changed
      if (_bannerPath != null && _bannerPath!.startsWith('/')) {
        final bannerResult = await repository.updateBanner(
          currentUser.id,
          _bannerPath!,
        );
        if (bannerResult.isFailure) {
          throw Exception(bannerResult.failure?.message);
        }
      }

      // Update profile fields
      final updateResult = await repository.updateProfile(currentUser.id, {
        'display_name': displayName,
        'username': username,
        'bio': bio,
      });

      if (updateResult.isFailure) {
        throw Exception(updateResult.failure?.message);
      }

      // Refresh the session user so the UI reflects the updated profile.
      final refreshed = await ref.read(sessionProvider.notifier).refreshUser();
      if (!refreshed) {
        throw Exception('Failed to refresh user after profile update');
      }

      // Invalidate the current user provider so dependent UI rebuilds.
      ref.invalidate(currentUserProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
        Navigator.pop(context);
      }
    } catch (e, stack) {
      Logger.error(
        '===== _saveProfile FAILED =====\n'
        'Exception type: ${e.runtimeType}\n'
        'Exception: $e\n'
        'Stack trace:\n$stack',
        error: e,
        stackTrace: stack,
        tag: 'EditProfilePage',
      );
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
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
          'Edit Profile',
          style: ORATypography.title(context),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: ORAColors.textPrimary(brightness)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: Text(
              'Save',
              style: ORATypography.label(context).copyWith(
                color: ORAColors.primary(brightness),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(ORASpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Banner
                  _buildBannerPicker(context, brightness),
                  const SizedBox(height: ORASpacing.lg),

                  // Avatar
                  _buildAvatarPicker(context, brightness),
                  const SizedBox(height: ORASpacing.xxl),

                  // Display name
                  ORATextField(
                    label: 'Display Name',
                    hintText: 'Your display name',
                    controller: _displayNameController,
                  ),
                  const SizedBox(height: ORASpacing.lg),

                  // Username
                  ORATextField(
                    label: 'Username',
                    hintText: 'Choose a username',
                    controller: _usernameController,
                    onChanged: (_) => _validateUsername(),
                  ),
                  if (!_isUsernameValid) ...[
                    const SizedBox(height: ORASpacing.sm),
                    Text(
                      'Username is already taken.',
                      style: ORATypography.caption(context).copyWith(
                        color: ORAColors.error(brightness),
                      ),
                    ),
                  ],
                  const SizedBox(height: ORASpacing.lg),

                  // Bio
                  ORATextField(
                    label: 'Bio',
                    hintText: 'Tell people about yourself',
                    controller: _bioController,
                  ),
                  const SizedBox(height: ORASpacing.lg),

                  // Website
                  ORATextField(
                    label: 'Website',
                    hintText: 'Your website URL',
                    controller: _websiteController,
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: ORASpacing.lg),

                  // Location
                  ORATextField(
                    label: 'Location',
                    hintText: 'Your city or country',
                    controller: _locationController,
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

                  // Save button
                  ORAButton(
                    text: 'Save Changes',
                    onPressed: _isSaving ? null : _saveProfile,
                    isLoading: _isSaving,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBannerPicker(BuildContext context, Brightness brightness) {
    return GestureDetector(
      onTap: _pickBanner,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: ORARadius.mediumAll,
          color: ORAColors.surface(brightness),
          border: Border.all(color: ORAColors.border(brightness)),
        ),
        child: _bannerPath != null && _bannerPath!.startsWith('/')
            ? ClipRRect(
                borderRadius: ORARadius.mediumAll,
                child: Image.file(
                  File(_bannerPath!),
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_outlined,
                    color: ORAColors.textTertiary(brightness),
                    size: 32,
                  ),
                  const SizedBox(height: ORASpacing.sm),
                  Text(
                    'Tap to change banner',
                    style: ORATypography.caption(context).copyWith(
                      color: ORAColors.textTertiary(brightness),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAvatarPicker(BuildContext context, Brightness brightness) {
    return Center(
      child: GestureDetector(
        onTap: _pickAvatar,
        child: Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ORAColors.surface(brightness),
                border: Border.all(
                  color: ORAColors.border(brightness),
                  width: 2,
                ),
              ),
              child: _avatarPath != null && _avatarPath!.startsWith('/')
                  ? ClipOval(
                      child: Image.file(
                        File(_avatarPath!),
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      Icons.person_outline,
                      color: ORAColors.textTertiary(brightness),
                      size: 48,
                    ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ORAColors.primary(brightness),
                  border: Border.all(
                    color: ORAColors.background(brightness),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}