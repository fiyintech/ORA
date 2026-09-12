import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/aura/aura_provider.dart';
import 'package:mobile/core/backend/repositories/impl/providers.dart';
import 'package:mobile/core/theme/ora_animations.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/core/theme/ora_radius.dart';
import 'package:mobile/core/theme/ora_spacing.dart';
import 'package:mobile/core/theme/ora_typography.dart';
import 'package:mobile/features/session/session_provider.dart';
import 'package:mobile/models/aura.dart';
import 'package:mobile/shared/widgets/ora_aura_card.dart';
import 'package:mobile/shared/widgets/ora_empty_state.dart';
import 'package:mobile/shared/widgets/ora_loading_indicator.dart';
import 'package:mobile/shared/widgets/ora_section_header.dart';
import 'package:mobile/shared/widgets/ora_steeze_card.dart';

class AuraPage extends ConsumerStatefulWidget {
  const AuraPage({super.key});

  @override
  ConsumerState<AuraPage> createState() => _AuraPageState();
}

class _AuraPageState extends ConsumerState<AuraPage> {
  List<Achievement> _achievements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    setState(() => _isLoading = true);
    final repository = ref.read(auraRepositoryProvider);
    final user = ref.read(currentUserProvider);
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    final userId = user.id;
    
    final achievements = await repository.getAchievements(userId);
    
    if (mounted) {
      setState(() {
        _achievements = achievements;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final user = ref.watch(currentUserProvider);
    final auraEngine = ref.read(auraEngineProvider);
    if (user == null) {
      return Scaffold(
        backgroundColor: ORAColors.background(brightness),
        body: const Center(
          child: ORALoadingIndicator(),
        ),
      );
    }
    final userId = user.id;

    // Read real Aura values from the engine
    final totalAura = auraEngine.calculateTotal(userId);

    // Calculate steeze level from Aura (simple formula: level = total / 100)
    final steezeLevel = (totalAura / 100).floor() + 1;
    final auraToNextLevel = totalAura % 100;
    final totalAuraForNextLevel = 100;

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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(ORASpacing.lg, ORASpacing.lg, ORASpacing.lg, ORASpacing.sm),
                child: Text(
                  'Aura',
                  style: ORATypography.heading(context),
                ),
              ),
              // Aura Points Card
              ORAAuraCard(
                title: 'Aura Points',
                icon: Icons.auto_awesome_rounded,
                auraValue: '$totalAura',
                valueFontSize: 56,
                bottom: Column(
                  children: [
                    const SizedBox(height: ORASpacing.md),
                    // Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(context, 'Current Rank', '--', brightness),
                        Container(
                          width: 1,
                          height: 40,
                          color: ORAColors.border(brightness),
                        ),
                        _buildStatItem(context, 'Steeze', 'Lvl $steezeLevel', brightness),
                        Container(
                          width: 1,
                          height: 40,
                          color: ORAColors.border(brightness),
                        ),
                        _buildStatItem(context, 'Weekly Gain', '--', brightness),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: ORASpacing.lg),
              // Steeze Level
              ORASteezeCard(
                icon: Icons.trending_up_rounded,
                title: 'Steeze Level',
                levelChipText: 'Lvl $steezeLevel',
                progress: auraToNextLevel / totalAuraForNextLevel,
                leftLabel: '$auraToNextLevel / $totalAuraForNextLevel Aura',
                rightLabel: 'Lvl ${steezeLevel + 1}',
              ),
              const SizedBox(height: ORASpacing.lg),
              // Aura Milestones
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: ORASpacing.lg),
                child: ORASectionHeader(
                  title: 'Aura Milestones',
                ),
              ),
              const SizedBox(height: ORASpacing.md),
              _buildMilestonesSection(context, brightness, totalAura),
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
              const SizedBox(height: ORASpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, Brightness brightness) {
    return Column(
      children: [
        Text(
          value,
          style: ORATypography.title(context).copyWith(
            color: ORAColors.textPrimary(brightness),
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: ORATypography.caption(context).copyWith(
            color: ORAColors.textSecondary(brightness),
          ),
        ),
      ],
    );
  }

  Widget _buildMilestonesSection(BuildContext context, Brightness brightness, int currentAura) {
    final milestones = [100, 500, 1000, 5000, 10000, 25000, 50000, 100000];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: milestones.length,
        itemBuilder: (context, index) {
          final milestone = milestones[index];
          final isUnlocked = currentAura >= milestone;
          final isCurrent = currentAura < milestone && (index == 0 || currentAura >= milestones[index - 1]);

          return Container(
            width: 100,
            margin: EdgeInsets.only(right: index < milestones.length - 1 ? ORASpacing.md : 0),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? ORAColors.accent(brightness).withValues(alpha: 0.1)
                  : ORAColors.surface(brightness).withValues(alpha: 0.5),
              borderRadius: ORARadius.mediumAll,
              border: Border.all(
                color: isUnlocked
                    ? ORAColors.accent(brightness).withValues(alpha: 0.3)
                    : ORAColors.border(brightness),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: isUnlocked ? ORAColors.accent(brightness) : ORAColors.textTertiary(brightness),
                  size: 24,
                ),
                const SizedBox(height: ORASpacing.sm),
                Text(
                  '${(milestone / 1000).toStringAsFixed(0)}K',
                  style: ORATypography.label(context).copyWith(
                    color: isUnlocked ? ORAColors.accent(brightness) : ORAColors.textSecondary(brightness),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (isCurrent)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: ORAColors.primary(brightness).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Next',
                      style: ORATypography.caption(context).copyWith(
                        color: ORAColors.primary(brightness),
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ).animate().fadeIn(duration: ORAAnimations.fast, delay: Duration(milliseconds: index * 50));
        },
      ),
    );
  }

  Widget _buildAchievementsSection(BuildContext context, Brightness brightness) {
    if (_achievements.isEmpty) {
      return ORAEmptyState(
        title: 'No achievements yet',
        description: 'Start engaging to earn your first badge.',
        icon: Icons.emoji_events_outlined,
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: ORASpacing.lg),
        itemCount: _achievements.length,
        itemBuilder: (context, index) {
          final achievement = _achievements[index];
          return Container(
            width: 160,
            margin: EdgeInsets.only(right: index < _achievements.length - 1 ? ORASpacing.md : 0),
            decoration: BoxDecoration(
              color: achievement.isUnlocked
                  ? ORAColors.accent(brightness).withValues(alpha: 0.1)
                  : ORAColors.surface(brightness).withValues(alpha: 0.5),
              borderRadius: ORARadius.mediumAll,
              border: Border.all(
                color: achievement.isUnlocked
                    ? ORAColors.accent(brightness).withValues(alpha: 0.3)
                    : ORAColors.border(brightness),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  color: achievement.isUnlocked
                      ? ORAColors.accent(brightness)
                      : ORAColors.textTertiary(brightness),
                  size: 32,
                ),
                const SizedBox(height: ORASpacing.sm),
                Text(
                  achievement.title,
                  style: ORATypography.label(context).copyWith(
                    color: achievement.isUnlocked
                        ? ORAColors.textPrimary(brightness)
                        : ORAColors.textSecondary(brightness),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: ORATypography.caption(context).copyWith(
                    color: ORAColors.textTertiary(brightness),
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (achievement.isUnlocked) ...[
                  const SizedBox(height: 4),
                  Text(
                    '+${achievement.auraReward} Aura',
                    style: ORATypography.caption(context).copyWith(
                      color: ORAColors.accent(brightness),
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ).animate().fadeIn(duration: ORAAnimations.fast, delay: Duration(milliseconds: index * 50));
        },
      ),
    );
  }

}