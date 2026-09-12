import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/backend/repositories/impl/providers.dart';
import 'package:mobile/core/services/share_service.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/core/theme/ora_radius.dart';
import 'package:mobile/core/theme/ora_spacing.dart';
import 'package:mobile/core/theme/ora_typography.dart';
import 'package:mobile/features/session/session_provider.dart';
import 'package:mobile/shared/widgets/ora_aura_card.dart';
import 'package:mobile/shared/widgets/ora_avatar.dart';
import 'package:mobile/shared/widgets/ora_button.dart';
import 'package:mobile/shared/widgets/ora_loading_indicator.dart';
import 'package:mobile/shared/widgets/ora_stat_card.dart';
import 'package:mobile/shared/widgets/ora_steeze_card.dart';

class PublicProfilePage extends ConsumerStatefulWidget {
  final String userId;

  const PublicProfilePage({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends ConsumerState<PublicProfilePage> {
  Map<String, dynamic>? _profileStats;
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isFollowLoading = false;
  String _username = 'User';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    final repository = ref.read(profileRepositoryProvider);
    final followRepo = ref.read(followRepositoryProvider);
    final currentUser = ref.read(currentUserProvider);

    // Fetch full profile data
    final profile = await repository.getProfile(widget.userId);
    
    // Check if user exists
    if (profile.value == null && mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found')),
      );
      Navigator.pop(context);
      return;
    }
    
    final stats = await repository.getProfileStats(widget.userId);
    final isFollowingResult = await followRepo.isFollowing(
      currentUser?.id ?? '',
      widget.userId,
    );

    if (mounted) {
      setState(() {
        _profileStats = stats;
        _isFollowing = isFollowingResult.value ?? false;
        _username = stats['username'] ?? 'User';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (_isFollowLoading) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() => _isFollowLoading = true);
    final followRepo = ref.read(followRepositoryProvider);

    if (_isFollowing) {
      await followRepo.unfollowUser(currentUser.id, widget.userId);
    } else {
      await followRepo.followUser(currentUser.id, widget.userId);
    }

    if (mounted) {
      setState(() {
        _isFollowing = !_isFollowing;
        _isFollowLoading = false;
      });
      // Refresh stats
      _loadProfileData();
    }
  }

  Future<void> _shareProfile() async {
    try {
      final shareService = ShareService();
      await shareService.shareProfile(widget.userId, _username);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to share')),
        );
      }
    }
  }

  Future<void> _messageUser() async {
    // TODO: Navigate to conversation with this user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Messages coming soon')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: ORAColors.background(brightness),
        body: const Center(
          child: ORALoadingIndicator(),
        ),
      );
    }

    final aura = _profileStats?['aura'] ?? 0;
    final followers = _profileStats?['followers'] ?? 0;
    final following = _profileStats?['following'] ?? 0;
    final posts = _profileStats?['posts'] ?? 0;
    final username = _profileStats?['username'] ?? 'User';
    final fullName = _profileStats?['fullName'] ?? username;
    final bio = _profileStats?['bio'] ?? '';

    return Scaffold(
      backgroundColor: ORAColors.background(brightness),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadProfileData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Banner
              _buildProfileBanner(context, brightness),
              const SizedBox(height: ORASpacing.xxl),

              // Profile Header
              _buildProfileHeader(context, fullName, username, bio, brightness),
              const SizedBox(height: ORASpacing.xxl),

              // Action Buttons
              _buildActionButtons(context, brightness),
              const SizedBox(height: ORASpacing.lg),

              // Stats
              _buildStatsSection(context, brightness, aura, followers, following, posts),
              const SizedBox(height: ORASpacing.lg),

              // Aura Card
              ORAAuraCard(
                title: 'Aura',
                icon: Icons.auto_awesome_rounded,
                auraValue: '$aura',
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
                levelChipText: 'Lvl ${(aura / 100).floor() + 1}',
                progress: (aura % 100) / 100,
                leftLabel: 'Level ${(aura / 100).floor() + 1}',
                rightLabel: 'Next: Level ${(aura / 100).floor() + 2}',
              ),
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

  Widget _buildProfileHeader(BuildContext context, String fullName, String username, String bio, Brightness brightness) {
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
                letter: fullName,
                size: 120,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Display Name
          Text(
            fullName,
            style: ORATypography.heading(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          // Username
          Text(
            '@$username',
            style: ORATypography.caption(context).copyWith(
              color: ORAColors.textSecondary(brightness),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          // Bio
          if (bio.isNotEmpty) ...[
            const SizedBox(height: ORASpacing.sm),
            Text(
              bio,
              style: ORATypography.caption(context).copyWith(
                color: ORAColors.textSecondary(brightness),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Brightness brightness) {
    final currentUser = ref.read(currentUserProvider);
    final isOwnProfile = currentUser?.id == widget.userId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ORASpacing.lg),
      child: Row(
        children: [
          if (!isOwnProfile) ...[
            Expanded(
              child: ORAButton(
                text: _isFollowing ? 'Following' : 'Follow',
                onPressed: _isFollowLoading ? null : _toggleFollow,
                isPrimary: !_isFollowing,
                isFullWidth: true,
              ),
            ),
            const SizedBox(width: ORASpacing.md),
            Expanded(
              child: ORAButton(
                text: 'Message',
                onPressed: _messageUser,
                isPrimary: false,
                isFullWidth: true,
              ),
            ),
            const SizedBox(width: ORASpacing.md),
          ],
          ORAButton(
            text: 'Share',
            onPressed: _shareProfile,
            isPrimary: false,
            isFullWidth: !isOwnProfile,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, Brightness brightness, int aura, int followers, int following, int posts) {
    final stats = [
      {'icon': Icons.auto_awesome_rounded, 'label': 'Aura', 'value': '$aura'},
      {'icon': Icons.article_outlined, 'label': 'Posts', 'value': '$posts'},
      {'icon': Icons.people_outlined, 'label': 'Followers', 'value': '$followers'},
      {'icon': Icons.person_outlined, 'label': 'Following', 'value': '$following'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ORASpacing.lg),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: ORASpacing.md,
        crossAxisSpacing: ORASpacing.md,
        childAspectRatio: 1.5,
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
}