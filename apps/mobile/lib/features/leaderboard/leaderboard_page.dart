import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile/core/theme/ora_animations.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/core/theme/ora_radius.dart';
import 'package:mobile/core/theme/ora_spacing.dart';
import 'package:mobile/core/theme/ora_typography.dart';
import 'package:mobile/models/leaderboard.dart';
import 'package:mobile/shared/widgets/ora_avatar.dart';
import 'package:mobile/shared/widgets/ora_ranking_row.dart';
import 'package:mobile/shared/widgets/ora_empty_state.dart';
import 'package:mobile/shared/widgets/ora_loading_indicator.dart';
import 'package:mobile/shared/widgets/ora_section_header.dart';
import 'package:mobile/core/backend/repositories/impl/providers.dart';

class LeaderboardPage extends ConsumerStatefulWidget {
  const LeaderboardPage({super.key});

  @override
  ConsumerState<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends ConsumerState<LeaderboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _categoryTabController;
  int _selectedPeriod = 0;

  final List<String> _categoryTabs = ['Global', 'Country', 'City', 'Hoods', 'Friends'];
  final List<String> _periods = ['Weekly', 'Monthly', 'All-Time', 'Hall of Fame'];
  List<LeaderboardEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _categoryTabController = TabController(length: _categoryTabs.length, vsync: this);
    _categoryTabController.addListener(() {
      if (!_categoryTabController.indexIsChanging) {
        setState(() {});
      }
    });
    _loadLeaderboard();
  }

  @override
  void dispose() {
    _categoryTabController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);
    final repository = ref.read(leaderboardRepositoryProvider);
    final tab = _categoryTabs[_categoryTabController.index];
    
    List<LeaderboardEntry> entries;
    switch (tab) {
      case 'Global':
        entries = await repository.getGlobalLeaderboard();
        break;
      case 'Country':
        entries = await repository.getCountryLeaderboard();
        break;
      case 'City':
        entries = await repository.getCityLeaderboard();
        break;
      case 'Hoods':
        entries = await repository.getHoodLeaderboard();
        break;
      case 'Friends':
        entries = await repository.getGlobalLeaderboard();
        break;
      default:
        entries = await repository.getGlobalLeaderboard();
    }
    
    if (mounted) {
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: ORAColors.background(brightness),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(ORASpacing.lg, ORASpacing.lg, ORASpacing.lg, ORASpacing.sm),
              child: ORASectionHeader(
                title: 'Leaderboard',
              ),
            ),
            // Category tabs
            Container(
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: ORASpacing.lg, vertical: ORASpacing.sm),
              decoration: BoxDecoration(
                color: ORAColors.surface(brightness),
                borderRadius: ORARadius.mediumAll,
              ),
              child: TabBar(
                controller: _categoryTabController,
                indicator: BoxDecoration(
                  color: ORAColors.primary(brightness),
                  borderRadius: ORARadius.smallAll,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: ORAColors.textTertiary(brightness),
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                dividerColor: Colors.transparent,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: _categoryTabs.map((tab) => Tab(text: tab)).toList(),
              ),
            ),
            // Period tabs
            Container(
              height: 36,
              margin: const EdgeInsets.symmetric(horizontal: ORASpacing.lg, vertical: ORASpacing.xs),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _periods.length,
                separatorBuilder: (_, _) => const SizedBox(width: ORASpacing.sm),
                itemBuilder: (context, index) {
                  final isSelected = _selectedPeriod == index;
                  final isHallOfFame = index == 3;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedPeriod = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: ORASpacing.md, vertical: ORASpacing.sm),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isHallOfFame
                                ? ORAColors.accent(brightness).withValues(alpha: 0.15)
                                : ORAColors.primary(brightness).withValues(alpha: 0.2))
                            : ORAColors.surface(brightness),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? (isHallOfFame
                                  ? ORAColors.accent(brightness).withValues(alpha: 0.5)
                                  : ORAColors.primary(brightness).withValues(alpha: 0.5))
                              : ORAColors.border(brightness),
                        ),
                      ),
                      child: Text(
                        _periods[index],
                        style: ORATypography.caption(context).copyWith(
                          color: isSelected
                              ? (isHallOfFame ? ORAColors.accent(brightness) : ORAColors.primary(brightness))
                              : ORAColors.textTertiary(brightness),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: ORASpacing.sm),
            // Content
            Expanded(
              child: _selectedPeriod == 3
                  ? _buildHallOfFame(context, brightness)
                  : _buildLeaderboardContent(context, brightness),
            ),
            if (_isLoading)
              const LinearProgressIndicator(minHeight: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardContent(BuildContext context, Brightness brightness) {
    if (_isLoading) {
      return const Center(child: ORALoadingIndicator());
    }
    
    final entries = _entries;
    if (entries.isEmpty) {
      return ORAEmptyState(
        title: 'No rankings yet',
        description: 'Be the first to climb the leaderboard!',
        icon: Icons.leaderboard_outlined,
      );
    }
    final top3 = entries.take(3).toList();
    final rest = entries.skip(3).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: ORASpacing.lg),
      children: [
        // Top 3 Podium
        const SizedBox(height: ORASpacing.sm),
        _buildPodium(context, top3, brightness),
        const SizedBox(height: ORASpacing.xxl),
        // Rankings header
        Padding(
          padding: const EdgeInsets.only(left: ORASpacing.xs, bottom: ORASpacing.md),
          child: ORASectionHeader(
            title: 'Rankings',
          ),
        ),
        // Rankings list
        ...rest.asMap().entries.map((entry) {
          return Column(
            children: [
              ORARankingRow(
                rank: entry.key + 4,
                avatarLetter: entry.value.avatarLetter,
                avatarColors: entry.value.avatarColors,
                username: entry.value.username,
                auraPoints: entry.value.auraPoints,
                steezeLevel: entry.value.steezeLevel,
                prestigeBadge: entry.value.prestigeBadge,
              ),
              const SizedBox(height: ORASpacing.md),
            ],
          );
        }),
        const SizedBox(height: ORASpacing.xxl),
      ],
    );
  }

  Widget _buildPodium(BuildContext context, List<LeaderboardEntry> top3, Brightness brightness) {
    if (top3.isEmpty) return const SizedBox.shrink();

    // Reorder for display: 2nd (silver) left, 1st (gold) center, 3rd (bronze) right
    final displayOrder = [
      top3.length > 1 ? top3[1] : null, // Silver
      top3[0], // Gold
      top3.length > 2 ? top3[2] : null, // Bronze
    ];

    return SizedBox(
      height: 260,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Silver (2nd)
          Expanded(
            child: displayOrder[0] != null
                ? _buildPodiumCard(
                    context: context,
                    entry: displayOrder[0]!,
                    rank: 2,
                    color: ORAColors.silver,
                    height: 180,
                    delay: 100,
                    brightness: brightness,
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: ORASpacing.sm),
          // Gold (1st)
          Expanded(
            child: _buildPodiumCard(
              context: context,
              entry: displayOrder[1]!,
              rank: 1,
              color: ORAColors.gold,
              height: 220,
              delay: 0,
              brightness: brightness,
            ),
          ),
          const SizedBox(width: ORASpacing.sm),
          // Bronze (3rd)
          Expanded(
            child: displayOrder[2] != null
                ? _buildPodiumCard(
                    context: context,
                    entry: displayOrder[2]!,
                    rank: 3,
                    color: ORAColors.bronze,
                    height: 160,
                    delay: 200,
                    brightness: brightness,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumCard({
    required BuildContext context,
    required LeaderboardEntry entry,
    required int rank,
    required Color color,
    required double height,
    required int delay,
    required Brightness brightness,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: ORAColors.surface(brightness),
        borderRadius: ORARadius.largeAll,
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Crown for 1st
          if (rank == 1)
            Icon(Icons.auto_awesome_rounded, color: color, size: 24),
          if (rank == 1) const SizedBox(height: 4),
          // Rank badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: ORATypography.label(context).copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: ORASpacing.sm),
          // Avatar
          ORAAvatar(
            letter: entry.avatarLetter,
            size: rank == 1 ? 48 : 40,
            gradientColors: entry.avatarColors,
          ),
          const SizedBox(height: ORASpacing.sm),
          // Username
          Text(
            entry.username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ORATypography.caption(context).copyWith(
              color: ORAColors.textPrimary(brightness),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          // Aura Points
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, color: color, size: 12),
              const SizedBox(width: 2),
              Text(
                '${entry.auraPoints}',
                style: ORATypography.caption(context).copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: ORAAnimations.normal, delay: Duration(milliseconds: delay)).slideY(
          begin: 0.2,
          end: 0,
          duration: ORAAnimations.normal,
          delay: Duration(milliseconds: delay),
          curve: Curves.easeOut,
        );
  }

  Widget _buildHallOfFame(BuildContext context, Brightness brightness) {
    return Center(
      child: ORAEmptyState(
        title: 'No hall of fame yet',
        description: 'The most legendary users will appear here once the backend is ready.',
        icon: Icons.auto_awesome_rounded,
      ),
    );
  }
}