import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile/core/theme/ora_animations.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/core/theme/ora_radius.dart';
import 'package:mobile/core/theme/ora_spacing.dart';
import 'package:mobile/core/theme/ora_typography.dart';
import 'package:mobile/models/hood.dart';
import 'package:mobile/shared/widgets/ora_avatar.dart';
import 'package:mobile/shared/widgets/ora_button.dart';
import 'package:mobile/shared/widgets/ora_post_card.dart';
import 'package:mobile/shared/widgets/ora_ranking_row.dart';
import 'package:mobile/shared/widgets/ora_empty_state.dart';

// Removed unused _buildEmptyState method below.

class HoodDetailPage extends StatelessWidget {
  final Hood? hood;

  const HoodDetailPage({super.key, this.hood});

  @override
  Widget build(BuildContext context) {
    final hood = this.hood ??
        Hood(
          id: 'default',
          name: 'Unknown Hood',
          category: 'General',
          description: 'No description available',
          memberCount: 0,
          bannerColors: const [Color(0xFF6B3FA0), Color(0xFF8B5CF6)],
          icon: Icons.group,
          posts: const [],
          members: const [],
        );
    final brightness = Theme.of(context).brightness;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: ORAColors.background(brightness),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: ORAColors.background(brightness),
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: ORAColors.textSecondary(brightness)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ...hood.bannerColors,
                          ORAColors.background(brightness),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Spacer(),
                        // Hood icon
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(hood.icon, color: Colors.white, size: 32),
                        ),
                        const SizedBox(height: ORASpacing.md),
                        Text(
                          hood.name,
                          style: ORATypography.heading(context).copyWith(
                            color: Colors.white,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${hood.memberCount} members • ${hood.category}',
                          style: ORATypography.caption(context).copyWith(
                            color: ORAColors.textSecondary(brightness),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: ORASpacing.md),
                        // Join/Joined button
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 80),
                          child: ORAButton(
                            text: hood.isJoined ? 'Joined' : 'Join',
                            onPressed: () {},
                            isPrimary: !hood.isJoined,
                            isFullWidth: true,
                          ),
                        ),
                        const SizedBox(height: ORASpacing.md),
                      ],
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: Container(
                    color: ORAColors.background(brightness),
                    child: TabBar(
                      indicator: BoxDecoration(
                        color: ORAColors.primary(brightness),
                        borderRadius: ORARadius.smallAll,
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      unselectedLabelColor: ORAColors.textTertiary(brightness),
                      labelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Feed'),
                        Tab(text: 'Members'),
                        Tab(text: 'Leaderboard'),
                        Tab(text: 'About'),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              _buildFeedTab(context, brightness, hood),
              _buildMembersTab(context, brightness, hood),
              _buildLeaderboardTab(context, brightness, hood),
              _buildAboutTab(context, brightness),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedTab(BuildContext context, Brightness brightness, Hood hood) {
    final posts = hood.posts;
    if (posts.isEmpty) {
      return ORAEmptyState(
        title: 'No posts yet.',
        description: 'Be the first to share something.',
        icon: Icons.explore_outlined,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(ORASpacing.lg),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return Column(
          children: [
            ORAPostCard(
              avatarLetter: post.avatarLetter,
              avatarGradientColors: post.avatarColors,
              username: post.username,
              time: post.time,
              content: post.text,
              usernameTrailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ORAColors.primary(brightness).withValues(alpha: 0.2),
                  borderRadius: ORARadius.smallAll,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: ORAColors.primary(brightness),
                      size: 10,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${post.auraBadge}',
                      style: ORATypography.caption(context).copyWith(
                        color: ORAColors.primary(brightness),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              footerActions: [
                _buildAction(context, Icons.favorite_border, '${post.likes}', brightness),
                const SizedBox(width: ORASpacing.lg),
                _buildAction(context, Icons.chat_bubble_outline_rounded, '${post.comments}', brightness),
                const Spacer(),
                _buildAction(context, Icons.share_outlined, 'Share', brightness),
              ],
            ),
            const SizedBox(height: ORASpacing.md),
          ],
        );
      },
    );
  }

  Widget _buildAction(BuildContext context, IconData icon, String label, Brightness brightness) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: ORAColors.textTertiary(brightness), size: 18),
        const SizedBox(width: 6),
        Text(
          label,
          style: ORATypography.caption(context).copyWith(
            color: ORAColors.textTertiary(brightness),
          ),
        ),
      ],
    );
  }

  Widget _buildMembersTab(BuildContext context, Brightness brightness, Hood hood) {
    final members = hood.members;
    if (members.isEmpty) {
      return ORAEmptyState(
        title: 'No members yet.',
        description: 'Be the first to join this Hood.',
        icon: Icons.explore_outlined,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(ORASpacing.lg),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        return Container(
          margin: const EdgeInsets.only(bottom: ORASpacing.md),
          padding: const EdgeInsets.all(ORASpacing.md),
          decoration: BoxDecoration(
            color: ORAColors.surface(brightness),
            borderRadius: ORARadius.mediumAll,
            border: Border.all(color: ORAColors.border(brightness)),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  ORAAvatar(
                    letter: member.avatarLetter,
                    size: 44,
                    gradientColors: member.avatarColors,
                  ),
                  if (member.isOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: ORAColors.success(brightness),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ORAColors.surface(brightness),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: ORASpacing.md),
              Expanded(
                child: Text(
                  member.username,
                  style: ORATypography.label(context).copyWith(
                    color: ORAColors.textPrimary(brightness),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: ORASpacing.md, vertical: ORASpacing.sm),
                decoration: BoxDecoration(
                  color: ORAColors.primary(brightness).withValues(alpha: 0.15),
                  borderRadius: ORARadius.mediumAll,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: ORAColors.primary(brightness), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${member.auraPoints}',
                      style: ORATypography.label(context).copyWith(
                        color: ORAColors.primary(brightness),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: ORAAnimations.fast, delay: ORAAnimations.fast).slideY(
              begin: 0.05,
              end: 0,
              duration: ORAAnimations.fast,
              curve: Curves.easeOut,
            );
      },
    );
  }

  Widget _buildLeaderboardTab(BuildContext context, Brightness brightness, Hood hood) {
    final sortedMembers = List<HoodMember>.from(hood.members)
      ..sort((a, b) => b.auraPoints.compareTo(a.auraPoints));

    if (sortedMembers.isEmpty) {
      return ORAEmptyState(
        title: 'No leaderboard yet.',
        description: 'Start engaging to appear here.',
        icon: Icons.explore_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(ORASpacing.lg),
      itemCount: sortedMembers.length,
      itemBuilder: (context, index) {
        final member = sortedMembers[index];
        final rank = index + 1;

        return ORARankingRow(
          rank: rank,
          avatarLetter: member.avatarLetter,
          avatarColors: member.avatarColors,
          username: member.username,
          auraPoints: member.auraPoints,
        );
      },
    );
  }

  Widget _buildAboutTab(BuildContext context, Brightness brightness) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ORASpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: ORATypography.title(context),
          ),
          const SizedBox(height: ORASpacing.md),
          Text(
            hood!.description,
            style: ORATypography.body(context).copyWith(
              color: ORAColors.textSecondary(brightness),
              height: 1.6,
            ),
          ),
          const SizedBox(height: ORASpacing.xxl),
          Text(
            'Details',
            style: ORATypography.title(context),
          ),
          const SizedBox(height: ORASpacing.md),
          _buildDetailRow(context, 'Category', hood!.category, brightness),
          _buildDetailRow(context, 'Members', '${hood!.memberCount}', brightness),
          _buildDetailRow(context, 'Created', 'June 2026', brightness),
          _buildDetailRow(context, 'Type', 'Public', brightness),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ORASpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: ORATypography.caption(context).copyWith(
              color: ORAColors.textTertiary(brightness),
            ),
          ),
          Text(
            value,
            style: ORATypography.label(context).copyWith(
              color: ORAColors.textSecondary(brightness),
            ),
          ),
        ],
      ),
    );
  }
}
