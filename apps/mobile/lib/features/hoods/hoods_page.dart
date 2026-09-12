import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile/core/theme/ora_animations.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/core/theme/ora_radius.dart';
import 'package:mobile/core/theme/ora_shadows.dart';
import 'package:mobile/core/theme/ora_spacing.dart';
import 'package:mobile/core/theme/ora_typography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/events/events.dart';
import 'package:mobile/models/hood.dart';
import 'package:mobile/shared/widgets/ora_empty_state.dart';
import 'package:mobile/shared/widgets/ora_button.dart';
import 'package:mobile/shared/widgets/ora_loading_indicator.dart';
import 'package:mobile/core/backend/repositories/impl/providers.dart';
import 'package:mobile/features/session/session_provider.dart';

class HoodsPage extends ConsumerStatefulWidget {
  const HoodsPage({super.key});

  @override
  ConsumerState<HoodsPage> createState() => _HoodsPageState();
}

class _HoodsPageState extends ConsumerState<HoodsPage> {
  List<Hood> _featuredHoods = [];
  List<Hood> _yourHoods = [];
  List<Hood> _discoverHoods = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHoods();
  }

  Future<void> _loadHoods() async {
    setState(() => _isLoading = true);
    final repository = ref.read(hoodRepositoryProvider);
    
    final featured = await repository.getFeaturedHoods();
    final joined = await repository.getJoinedHoods();
    final discover = await repository.discoverHoods();
    
    if (mounted) {
      setState(() {
        _featuredHoods = featured;
        _yourHoods = joined;
        _discoverHoods = discover;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Data loaded via _loadHoods in initState
    final featuredHoods = _featuredHoods;
    final yourHoods = _yourHoods;
    final discoverHoods = _discoverHoods;
    final brightness = Theme.of(context).brightness;

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
              // App Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(ORASpacing.lg, ORASpacing.lg, ORASpacing.lg, ORASpacing.sm),
                child: Row(
                  children: [
                    Text(
                      'Hoods',
                      style: ORATypography.heading(context),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.search_rounded, color: ORAColors.textSecondary(brightness)),
                      onPressed: () => context.push("/search"),
                    ),
                    IconButton(
                      icon: Icon(Icons.filter_list_rounded, color: ORAColors.textSecondary(brightness)),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
               // Featured Hoods
               if (featuredHoods.isEmpty && yourHoods.isEmpty && discoverHoods.isEmpty) ...[
                SizedBox(height: ORASpacing.xxl),
                ORAEmptyState(
                  title: 'No hoods yet',
                  description: 'Join or create a hood to get started.',
                  icon: Icons.groups_outlined,
                ),
              ] else ...[
              Padding(
                padding: const EdgeInsets.only(left: ORASpacing.lg, bottom: ORASpacing.md),
                child: Text(
                  'Featured Hoods',
                  style: ORATypography.title(context),
                ),
              ),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: ORASpacing.lg, right: ORASpacing.sm),
                  itemCount: featuredHoods.length,
                  itemBuilder: (context, index) {
                    return _buildFeaturedCard(context, featuredHoods[index], brightness);
                  },
                ),
              ),
              const SizedBox(height: ORASpacing.xxl),
              // Your Hoods
              if (yourHoods.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(left: ORASpacing.lg, bottom: ORASpacing.md),
                  child: Text(
                    'Your Hoods',
                    style: ORATypography.title(context),
                  ),
                ),
                ...yourHoods.map((hood) => _buildYourHoodTile(context, hood, brightness)),
                const SizedBox(height: ORASpacing.xxl),
              ],
              // Discover
              Padding(
                padding: const EdgeInsets.only(left: ORASpacing.lg, bottom: ORASpacing.md),
                child: Text(
                  'Discover',
                  style: ORATypography.title(context),
                ),
              ),
              ...discoverHoods.map((hood) => _buildDiscoverCard(context, ref, hood, brightness)),
              const SizedBox(height: ORASpacing.xxxl),
              ],
            ],
          ),
        ),
        ),
      ).animate().fadeIn(duration: ORAAnimations.normal, delay: ORAAnimations.fast).slideX(
          begin: 0.1,
          end: 0,
          duration: ORAAnimations.normal,
          curve: Curves.easeOut,
        );
  }

  Widget _buildFeaturedCard(BuildContext context, Hood hood, Brightness brightness) {
    return GestureDetector(
      onTap: () {
        context.push("/hood-detail", extra: hood);
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: ORASpacing.md),
        decoration: BoxDecoration(
          borderRadius: ORARadius.largeAll,
          gradient: LinearGradient(
            colors: hood.bannerColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: ORAShadows.medium,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(ORASpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(hood.icon, color: Colors.white, size: 28),
                  const SizedBox(height: ORASpacing.sm),
                  Text(
                    hood.name,
                    style: ORATypography.title(context).copyWith(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hood.category,
                    style: ORATypography.caption(context).copyWith(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: ORASpacing.sm),
                  Row(
                    children: [
                      Icon(Icons.people_outlined, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${hood.memberCount}',
                        style: ORATypography.caption(context).copyWith(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: ORASpacing.md,
                          vertical: ORASpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Join',
                          style: ORATypography.label(context).copyWith(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYourHoodTile(BuildContext context, Hood hood, Brightness brightness) {
    return GestureDetector(
      onTap: () {
        context.push("/hood-detail", extra: hood);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: ORASpacing.lg, vertical: ORASpacing.xs),
        padding: const EdgeInsets.all(ORASpacing.md),
        decoration: BoxDecoration(
          color: ORAColors.surface(brightness),
          borderRadius: ORARadius.mediumAll,
          border: Border.all(color: ORAColors.border(brightness)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: hood.bannerColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(hood.icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: ORASpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hood.name,
                    style: ORATypography.label(context).copyWith(
                      color: ORAColors.textPrimary(brightness),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hood.lastActivity,
                    style: ORATypography.caption(context),
                  ),
                ],
              ),
            ),
            if (hood.unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: ORASpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: ORAColors.primary(brightness),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${hood.unreadCount}',
                  style: ORATypography.caption(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverCard(BuildContext context, WidgetRef ref, Hood hood, Brightness brightness) {
    final currentUser = ref.read(currentUserProvider);
    final userId = currentUser?.id ?? '';

    return GestureDetector(
      onTap: () {
        context.push("/hood-detail", extra: hood);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: ORASpacing.lg, vertical: ORASpacing.xs),
        padding: const EdgeInsets.all(ORASpacing.lg),
        decoration: BoxDecoration(
          color: ORAColors.surface(brightness),
          borderRadius: ORARadius.mediumAll,
          border: Border.all(color: ORAColors.border(brightness)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: hood.bannerColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(hood.icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: ORASpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hood.name,
                    style: ORATypography.label(context).copyWith(
                      color: ORAColors.textPrimary(brightness),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hood.description.length > 60
                        ? '${hood.description.substring(0, 60)}...'
                        : hood.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ORATypography.caption(context),
                  ),
                ],
              ),
            ),
            const SizedBox(width: ORASpacing.sm),
            ORAButton(
              text: 'Join',
              onPressed: () {
                if (userId.isEmpty) return;
                final eventBus = ref.read(eventBusProvider);
                eventBus.publish(UserJoinedHoodEvent(
                  userId: userId,
                  hoodId: hood.id,
                ));
              },
              isPrimary: true,
              isFullWidth: false,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: ORAAnimations.fast, delay: ORAAnimations.fast).slideY(
          begin: 0.05,
          end: 0,
          duration: ORAAnimations.fast,
          curve: Curves.easeOut,
        );
  }
}
