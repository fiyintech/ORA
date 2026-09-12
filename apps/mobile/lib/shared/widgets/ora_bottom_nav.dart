import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/backend/repositories/impl/notification_providers.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/core/theme/ora_spacing.dart';
import 'package:mobile/core/theme/ora_typography.dart';
import 'package:mobile/features/home/home_page.dart';
import 'package:mobile/features/chats/chats_page.dart';
import 'package:mobile/features/hoods/hoods_page.dart';
import 'package:mobile/features/leaderboard/leaderboard_page.dart';
import 'package:mobile/features/profile/profile_page.dart';
import 'package:mobile/features/notifications/notifications_page.dart';
import 'package:mobile/features/session/session_provider.dart';

class ORABottomNav extends ConsumerStatefulWidget {
  const ORABottomNav({super.key});

  @override
  ConsumerState<ORABottomNav> createState() => _ORABottomNavState();
}

class _ORABottomNavState extends ConsumerState<ORABottomNav> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    ChatsPage(),
    HoodsPage(),
    LeaderboardPage(),
    ProfilePage(),
  ];

  void _onTabTapped(int index) {
    if (index == 5) {
      // Navigate to notifications page
      if (mounted) {
        GoRouter.of(context).push('/notifications');
      }
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final userId = ref.watch(currentUserProvider)?.id ?? '';

    return Scaffold(
      backgroundColor: ORAColors.background(brightness),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: ORAColors.border(brightness),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          backgroundColor: ORAColors.background(brightness),
          selectedItemColor: ORAColors.primary(brightness), // Royal Purple
          unselectedItemColor: ORAColors.textTertiary(brightness),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Chats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups_outlined),
              activeIcon: Icon(Icons.groups),
              label: 'Hoods',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.leaderboard_outlined),
              activeIcon: Icon(Icons.leaderboard),
              label: 'Leaderboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: _buildNotificationIcon(brightness, userId),
              activeIcon: Icon(Icons.notifications),
              label: 'Alerts',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(Brightness brightness, String userId) {
    if (userId.isEmpty) {
      return const Icon(Icons.notifications_outlined);
    }

    return Consumer(
      builder: (context, ref, child) {
        final unreadCountAsync = ref.watch(notificationUnreadCountProvider(userId));

        return unreadCountAsync.when(
          loading: () => const Icon(Icons.notifications_outlined),
          error: (_, __) => const Icon(Icons.notifications_outlined),
          data: (count) {
            if (count == 0) {
              return const Icon(Icons.notifications_outlined);
            }

            return Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined),
                Positioned(
                  right: -8,
                  top: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: ORAColors.background(brightness),
                        width: 1.5,
                      ),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: ORATypography.caption(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}