import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/core/theme/ora_spacing.dart';
import 'package:mobile/core/theme/ora_theme.dart';
import 'package:mobile/core/theme/ora_typography.dart';
import 'package:mobile/features/session/session_provider.dart';
import 'package:mobile/shared/widgets/ora_section_header.dart';

/// ORA Settings Page
///
/// Organized into sections:
/// - Profile
/// - Account
/// - Privacy
/// - Notifications
/// - Appearance
/// - Security
/// - About
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: ORAColors.background(brightness),
      appBar: AppBar(
        backgroundColor: ORAColors.background(brightness),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Settings',
          style: ORATypography.title(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(ORASpacing.lg),
        children: [
          // ── Profile ──
          const ORASectionHeader(title: 'Profile'),
          const SizedBox(height: ORASpacing.sm),
          _buildProfileSection(context, ref, currentUser),
          const SizedBox(height: ORASpacing.xxl),

          // ── Account ──
          const ORASectionHeader(title: 'Account'),
          const SizedBox(height: ORASpacing.sm),
          _buildAccountSection(context, ref),
          const SizedBox(height: ORASpacing.xxl),

          // ── Privacy ──
          const ORASectionHeader(title: 'Privacy'),
          const SizedBox(height: ORASpacing.sm),
          _buildPrivacySection(context, ref),
          const SizedBox(height: ORASpacing.xxl),

          // ── Notifications ──
          const ORASectionHeader(title: 'Notifications'),
          const SizedBox(height: ORASpacing.sm),
          _buildNotificationsSection(context, ref),
          const SizedBox(height: ORASpacing.xxl),

          // ── Appearance ──
          const ORASectionHeader(title: 'Appearance'),
          const SizedBox(height: ORASpacing.sm),
          _buildAppearanceSection(context, ref),
          const SizedBox(height: ORASpacing.xxl),

          // ── Security ──
          const ORASectionHeader(title: 'Security'),
          const SizedBox(height: ORASpacing.sm),
          _buildSecuritySection(context, ref),
          const SizedBox(height: ORASpacing.xxl),

          // ── About ──
          const ORASectionHeader(title: 'About'),
          const SizedBox(height: ORASpacing.sm),
          _buildAboutSection(context, ref),
          const SizedBox(height: ORASpacing.xxxl),
        ],
      ),
    );
  }

  // ── Profile Section ──

  Widget _buildProfileSection(
    BuildContext context,
    WidgetRef ref,
    dynamic currentUser,
  ) {
    return _buildSettingsCard(
      context,
      children: [
        _buildSettingsTile(
          context,
          icon: Icons.person_outline,
          title: 'Edit Profile',
          subtitle: currentUser?.username != null
              ? '@${currentUser.username}'
              : 'Update your profile',
          onTap: () => context.push('/edit-profile'),
        ),
        _buildDivider(context),
        _buildSettingsTile(
          context,
          icon: Icons.badge_outlined,
          title: 'Username',
          subtitle: currentUser?.username ?? 'Set your username',
          onTap: () => context.push('/edit-profile'),
        ),
        _buildDivider(context),
        _buildSettingsTile(
          context,
          icon: Icons.info_outline,
          title: 'Bio',
          subtitle: 'Tell people about yourself',
          onTap: () => context.push('/edit-profile'),
        ),
      ],
    );
  }

  // ── Account Section ──

  Widget _buildAccountSection(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return _buildSettingsCard(
      context,
      children: [
        _buildSettingsTile(
          context,
          icon: Icons.email_outlined,
          title: 'Email',
          subtitle: currentUser?.email ?? 'No email set',
          onTap: () => context.push('/change-email'),
        ),
        _buildDivider(context),
        _buildSettingsTile(
          context,
          icon: Icons.logout_outlined,
          title: 'Logout',
          subtitle: 'Sign out of your account',
          onTap: () => _confirmLogout(context, ref),
        ),
      ],
    );
  }

  // ── Privacy Section ──

  Widget _buildPrivacySection(BuildContext context, WidgetRef ref) {
    return _buildSettingsCard(
      context,
      children: [
        _buildSettingsTile(
          context,
          icon: Icons.public_outlined,
          title: 'Public Profile',
          subtitle: 'Everyone can see your profile',
          trailing: Switch(
            value: true,
            onChanged: (_) {},
          ),
        ),
        _buildDivider(context),
        _buildSettingsTile(
          context,
          icon: Icons.visibility_outlined,
          title: 'Private Account',
          subtitle: 'Only followers can see your posts',
          trailing: Switch(
            value: false,
            onChanged: (_) {},
          ),
        ),
      ],
    );
  }

  // ── Notifications Section ──

  Widget _buildNotificationsSection(BuildContext context, WidgetRef ref) {
    return _buildSettingsCard(
      context,
      children: [
        _buildSettingsTile(
          context,
          icon: Icons.favorite_outline,
          title: 'Likes',
          subtitle: 'When someone likes your post',
          trailing: Switch(
            value: true,
            onChanged: (_) {},
          ),
        ),
        _buildDivider(context),
        _buildSettingsTile(
          context,
          icon: Icons.chat_bubble_outline,
          title: 'Comments',
          subtitle: 'When someone comments on your post',
          trailing: Switch(
            value: true,
            onChanged: (_) {},
          ),
        ),
        _buildDivider(context),
        _buildSettingsTile(
          context,
          icon: Icons.people_outline,
          title: 'Followers',
          subtitle: 'When someone follows you',
          trailing: Switch(
            value: true,
            onChanged: (_) {},
          ),
        ),
      ],
    );
  }

  // ── Appearance Section ──

  Widget _buildAppearanceSection(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(oraThemeModeProvider);

    return _buildSettingsCard(
      context,
      children: [
        _buildSettingsTile(
          context,
          icon: Icons.palette_outlined,
          title: 'Theme',
          subtitle: _themeLabel(currentMode),
          onTap: () => _showThemeSelector(context, ref),
        ),
      ],
    );
  }

  // ── Security Section ──

  Widget _buildSecuritySection(BuildContext context, WidgetRef ref) {
    return _buildSettingsCard(
      context,
      children: [
        _buildSettingsTile(
          context,
          icon: Icons.lock_outline,
          title: 'Change Password',
          subtitle: 'Update your password',
          onTap: () => context.push('/change-password'),
        ),
        _buildDivider(context),
        _buildSettingsTile(
          context,
          icon: Icons.email_outlined,
          title: 'Change Email',
          subtitle: 'Update your email address',
          onTap: () => context.push('/change-email'),
        ),
      ],
    );
  }

  // ── About Section ──

  Widget _buildAboutSection(BuildContext context, WidgetRef ref) {
    return _buildSettingsCard(
      context,
      children: [
        _buildSettingsTile(
          context,
          icon: Icons.info_outline,
          title: 'Version',
          subtitle: '1.0.0',
          onTap: null,
        ),
        _buildDivider(context),
        _buildSettingsTile(
          context,
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          subtitle: 'Read our privacy policy',
          onTap: () {},
        ),
        _buildDivider(context),
        _buildSettingsTile(
          context,
          icon: Icons.description_outlined,
          title: 'Terms of Service',
          subtitle: 'Read our terms',
          onTap: () {},
        ),
      ],
    );
  }

  // ── Helpers ──

  Widget _buildSettingsCard(BuildContext context, {required List<Widget> children}) {
    final brightness = Theme.of(context).brightness;

    return Container(
      decoration: BoxDecoration(
        color: ORAColors.surface(brightness),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ORAColors.border(brightness)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final brightness = Theme.of(context).brightness;

    return ListTile(
      leading: Icon(icon, color: ORAColors.primary(brightness)),
      title: Text(title, style: ORATypography.label(context)),
      subtitle: Text(
        subtitle,
        style: ORATypography.caption(context).copyWith(
          color: ORAColors.textSecondary(brightness),
        ),
      ),
      trailing: trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: ORAColors.textTertiary(brightness),
          ),
      onTap: onTap,
    );
  }

  Widget _buildDivider(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Divider(
      height: 1,
      thickness: 1,
      color: ORAColors.border(brightness),
      indent: 16,
      endIndent: 16,
    );
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.system:
        return 'System';
    }
  }

  void _showThemeSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final currentMode = ref.watch(oraThemeModeProvider);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(ORASpacing.lg),
                  child: Text(
                    'Select Theme',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Dark'),
                  value: ThemeMode.dark,
                  groupValue: currentMode,
                  onChanged: (mode) => _updateTheme(ref, mode),
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Light'),
                  value: ThemeMode.light,
                  groupValue: currentMode,
                  onChanged: (mode) => _updateTheme(ref, mode),
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('System'),
                  value: ThemeMode.system,
                  groupValue: currentMode,
                  onChanged: (mode) => _updateTheme(ref, mode),
                ),
                const SizedBox(height: ORASpacing.lg),
              ],
            );
          },
        );
      },
    );
  }

  void _updateTheme(WidgetRef ref, ThemeMode? mode) {
    if (mode != null) {
      ref.read(oraThemeModeProvider.notifier).setThemeMode(mode);
      Navigator.pop(ref.context);
    }
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final brightness = Theme.of(context).brightness;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ORAColors.surface(brightness),
        title: Text(
          'Logout',
          style: ORATypography.title(context),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: ORATypography.body(context).copyWith(
            color: ORAColors.textSecondary(brightness),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: ORAColors.textSecondary(brightness)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Logout',
              style: TextStyle(color: ORAColors.error(brightness)),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await ref.read(sessionProvider.notifier).logout();
    }
  }
}