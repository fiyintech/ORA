import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/backend/repositories/impl/providers.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/core/theme/ora_theme.dart';
import 'package:mobile/core/theme/ora_radius.dart';
import 'package:mobile/core/theme/ora_spacing.dart';
import 'package:mobile/core/theme/ora_typography.dart';
import 'package:mobile/features/session/session_provider.dart';
import 'package:mobile/shared/widgets/ora_aura_card.dart';
import 'package:mobile/shared/widgets/ora_avatar.dart';
import 'package:mobile/shared/widgets/ora_button.dart';
import 'package:mobile/shared/widgets/ora_card.dart';
import 'package:mobile/shared/widgets/ora_empty_state.dart';
import 'package:mobile/shared/widgets/ora_loading_indicator.dart';
import 'package:mobile/shared/widgets/ora_section_header.dart';
import 'package:mobile/shared/widgets/ora_stat_card.dart';
import 'package:mobile/shared/widgets/ora_steeze_card.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  Map<String, dynamic>? _profileStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    final repository = ref.read(profileRepositoryProvider);
    final user = ref.read(currentUserProvider);
    
    if (user != null) {
      final stats = await repository.getProfileStats(user.id);
      
      if (mounted) {
        setState(() {
          _profileStats = stats;
          _isLoading = false;
        });
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final brightness = Theme.of(context).brightness;

    if (user == null) {
      return Scaffold(
        backgroundColor: ORAColors.background(brightness),
        body: Center(
          child: Text(
            'No user data',
            style: ORATypography.body(context),
          ),
        ),
      );
    }

    // Read Aura from real profile stats
    final totalAura = (_profileStats?['aura'] as int?) ?? 0;
    final steezeLevel = (totalAura / 100).floor() + 1;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: ORAColors.background(brightness),
        body: const Center(
          child: ORALoadingIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ORAColors.background(brightness),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Banner
              _buildProfileBanner(context, brightness),
              const SizedBox(height: ORASpacing.xxl),

              // Profile Header
              _buildProfileHeader(context, user, brightness),
              const SizedBox(height: ORASpacing.md),

              // Edit Profile button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: ORASpacing.lg),
                child: ORAButton(
                  text: 'Edit Profile',
                  onPressed: () => context.push('/edit-profile'),
                  isPrimary: false,
                ),
              ),
              const SizedBox(height: ORASpacing.xxl),

              // Aura Card
              ORAAuraCard(
                title: 'Aura',
                icon: Icons.auto_awesome_rounded,
                auraValue: '$totalAura',
                valueFontSize: 48,
                bottom: Column(
                  children: [
                    const SizedBox(height: ORASpacing.sm),
                    Text(
                      'Current Global Rank',
                      style: ORATypography.caption(context).copyWith(
                        color: ORAColors.textSecondary(brightness),
                      ),
                    ),
                    const SizedBox(height: ORASpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ORASpacing.md,
                        vertical: ORASpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: ORAColors.surface(brightness).withValues(alpha: 0.5),
                        borderRadius: ORARadius.mediumAll,
                      ),
                      child: Text(
                        '--',
                        style: ORATypography.label(context).copyWith(
                          color: ORAColors.textPrimary(brightness),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: ORASpacing.lg),

              // Steeze Card
              ORASteezeCard(
                icon: Icons.trending_up_rounded,
                title: 'Steeze Level',
                levelChipText: 'Lvl $steezeLevel',
                progress: (totalAura % 100) / 100,
                leftLabel: 'Level $steezeLevel',
                rightLabel: 'Next: Level ${steezeLevel + 1}',
              ),
              const SizedBox(height: ORASpacing.lg),

              // Statistics
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: ORASpacing.lg),
                child: ORASectionHeader(
                  title: 'Statistics',
                ),
              ),
              const SizedBox(height: ORASpacing.md),
              _buildStatisticsSection(context, brightness),
              const SizedBox(height: ORASpacing.lg),

              // Achievements
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: ORASpacing.lg),
                child: ORASectionHeader(
                  title: 'Achievements',
                ),
              ),
              const SizedBox(height: ORASpacing.md),
              _buildAchievementsSection(context, brightness),
              const SizedBox(height: ORASpacing.lg),

              // Bookmarks Card
              _buildBookmarksSection(context, brightness),
              const SizedBox(height: ORASpacing.lg),

              // Theme Card
              _buildThemeSection(context, brightness),
              const SizedBox(height: ORASpacing.lg),

              // Logout
              _buildLogoutButton(context, ref),
              const SizedBox(height: ORASpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileBanner(BuildContext context, Brightness brightness) {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ORAColors.primary(brightness),
            ORAColors.secondary(brightness),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, dynamic user, Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ORASpacing.lg),
      child: Column(
        children: [
          // Avatar
          Transform.translate(
            offset: const Offset(0, -60),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: ORAColors.background(brightness),
                  width: 4,
                ),
              ),
              child: ORAAvatar(
                letter: user.fullName,
                size: 120,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Display Name
          Text(
            user.fullName,
            style: ORATypography.heading(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          // Username
          Text(
            '@${user.username}',
            style: ORATypography.caption(context).copyWith(
              color: ORAColors.textSecondary(brightness),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // Joined Date
          Text(
            'Joined ${_formatDate(user.createdAt)}',
            style: ORATypography.caption(context).copyWith(
              color: ORAColors.textTertiary(brightness),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(BuildContext context, Brightness brightness) {
    final stats = _profileStats != null
        ? [
            {'icon': Icons.article_outlined, 'label': 'Posts', 'value': '${_profileStats!['posts']}'},
            {'icon': Icons.favorite_outlined, 'label': 'Likes', 'value': '${_profileStats!['likes']}'},
            {'icon': Icons.chat_bubble_outline, 'label': 'Comments', 'value': '${_profileStats!['comments']}'},
            {'icon': Icons.groups_outlined, 'label': 'Hoods', 'value': '${_profileStats!['hoods']}'},
            {'icon': Icons.people_outlined, 'label': 'Followers', 'value': '${_profileStats!['followers']}'},
            {'icon': Icons.person_outlined, 'label': 'Following', 'value': '${_profileStats!['following']}'},
          ]
        : <Map<String, dynamic>>[];

    if (stats.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: ORASpacing.lg),
        child: ORAEmptyState(
          title: 'No statistics yet',
          description: 'Start engaging to see your stats.',
          icon: Icons.bar_chart_outlined,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ORASpacing.lg),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: ORASpacing.md,
        crossAxisSpacing: ORASpacing.md,
        childAspectRatio: 1.2,
        children: stats.map((stat) {
          return ORAStatCard(
            icon: stat['icon'] as IconData,
            value: stat['value'] as String,
            label: stat['label'] as String,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAchievementsSection(BuildContext context, Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ORASpacing.lg),
      child: ORACard(
        padding: const EdgeInsets.all(ORASpacing.xl),
        child: Column(
          children: [
            Icon(
              Icons.emoji_events_outlined,
              color: ORAColors.textTertiary(brightness),
              size: 48,
            ),
            const SizedBox(height: ORASpacing.md),
            Text(
              'No achievements yet.',
              style: ORATypography.body(context).copyWith(
                color: ORAColors.textSecondary(brightness),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Start engaging to earn your first badge.',
              style: ORATypography.caption(context).copyWith(
                color: ORAColors.textTertiary(brightness),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarksSection(BuildContext context, Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ORASpacing.lg),
      child: ORACard(
        padding: const EdgeInsets.all(ORASpacing.xl),
        child: Row(
          children: [
            Icon(
              Icons.bookmark_outline,
              color: ORAColors.primary(brightness),
              size: 24,
            ),
            const SizedBox(width: ORASpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bookmarks',
                    style: ORATypography.label(context),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'View your saved posts',
                    style: ORATypography.caption(context).copyWith(
                      color: ORAColors.textSecondary(brightness),
                    ),
                  ),
                ],
              ),
            ),
            ORAButton(
              text: 'View',
              onPressed: () => context.push('/bookmarks'),
              isPrimary: false,
              isFullWidth: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context, Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ORASpacing.lg),
      child: ORACard(
        padding: const EdgeInsets.all(ORASpacing.xl),
        child: Row(
          children: [
            Icon(
              Icons.palette_outlined,
              color: ORAColors.primary(brightness),
              size: 24,
            ),
            const SizedBox(width: ORASpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Theme',
                    style: ORATypography.label(context),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Dark Mode',
                    style: ORATypography.caption(context).copyWith(
                      color: ORAColors.textSecondary(brightness),
                    ),
                  ),
                ],
              ),
            ),
            ORAButton(
              text: 'Change Theme',
              onPressed: () => _showThemeSelector(context, ref),
              isPrimary: false,
              isFullWidth: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ORASpacing.lg),
      child: ORAButton(
        text: 'Logout',
        onPressed: () async {
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
        },
        isPrimary: false,
      ),
    );
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

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

}
