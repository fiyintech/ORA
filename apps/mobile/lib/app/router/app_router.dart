import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/session/session_provider.dart';
import 'package:mobile/features/splash/splash_page.dart';
import 'package:mobile/features/onboarding/onboarding_page.dart';
import 'package:mobile/features/auth/auth_page.dart';
import 'package:mobile/features/auth/login_page.dart';
import 'package:mobile/features/auth/signup_page.dart';
import 'package:mobile/features/auth/verify_email_page.dart';
import 'package:mobile/features/auth/forgot_password_page.dart';
import 'package:mobile/features/auth/change_password_page.dart';
import 'package:mobile/features/auth/change_email_page.dart';
import 'package:mobile/shared/widgets/ora_auth_guard.dart';
import 'package:mobile/features/chats/chats_page.dart';
import 'package:mobile/features/chats/conversation_page.dart';
import 'package:mobile/features/hoods/hoods_page.dart';
import 'package:mobile/features/hoods/hood_detail_page.dart';
import 'package:mobile/features/home/create_post_page.dart';
import 'package:mobile/features/home/bookmarks_page.dart';
import 'package:mobile/features/leaderboard/leaderboard_page.dart';
import 'package:mobile/features/aura/aura_page.dart';
import 'package:mobile/features/profile/profile_page.dart';
import 'package:mobile/features/profile/public_profile_page.dart';
import 'package:mobile/features/profile/edit_profile_page.dart';
import 'package:mobile/features/settings/settings_page.dart';
import 'package:mobile/features/gbedu/gbedu_page.dart';
import 'package:mobile/features/search/search_page.dart';
import 'package:mobile/features/notifications/notifications_page.dart';
import 'package:mobile/models/chat.dart';
import 'package:mobile/models/hood.dart';
import 'package:mobile/shared/widgets/ora_bottom_nav.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final sessionState = ref.watch(sessionProvider);
  final onboardingState = ref.watch(onboardingCompletedProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = sessionState.value != null;
      final isLoading = sessionState.isLoading || onboardingState.isLoading;
      final location = state.matchedLocation;
      final onboardingDone = onboardingState.value ?? true;

      // Show splash while loading
      if (isLoading) {
        // Avoid redirect loop when already on the splash route
        return location == '/' ? null : '/';
      }

      final isAuthRoute =
          location == '/auth' ||
          location == '/login' ||
          location == '/signup' ||
          location == '/verify-email' ||
          location == '/forgot-password';
      final isOnboardingRoute = location == '/onboarding';
      final isPublicRoute = isAuthRoute || isOnboardingRoute;

      if (!isLoggedIn) {
        if (!onboardingDone && !isOnboardingRoute) {
          return '/onboarding';
        }
        if (onboardingDone && isOnboardingRoute) {
          return '/auth';
        }
        if (!isPublicRoute) {
          return '/auth';
        }
        return null;
      }

      // If logged in and on auth route, onboarding, or splash, go to home
      if (isAuthRoute || isOnboardingRoute || location == '/') {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashPage()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(path: '/auth', builder: (context, state) => const AuthPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupPage()),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const VerifyEmailPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/change-password',
        builder: (context, state) =>
            const AuthGuard(child: ChangePasswordPage()),
      ),
      GoRoute(
        path: '/change-email',
        builder: (context, state) => const AuthGuard(child: ChangeEmailPage()),
      ),
      GoRoute(path: '/home', builder: (context, state) => const ORABottomNav()),
      GoRoute(path: '/chats', builder: (context, state) => const ChatsPage()),
      GoRoute(
        path: '/conversation',
        builder: (context, state) {
          final conversation = state.extra as Conversation?;
          return ConversationPage(conversation: conversation);
        },
      ),
      GoRoute(path: '/hoods', builder: (context, state) => const HoodsPage()),
      GoRoute(
        path: '/hood-detail',
        builder: (context, state) {
          final hood = state.extra as Hood?;
          return HoodDetailPage(hood: hood);
        },
      ),
      GoRoute(
        path: '/create-post',
        builder: (context, state) => const CreatePostPage(),
      ),
      GoRoute(
        path: '/bookmarks',
        builder: (context, state) => const AuthGuard(child: BookmarksPage()),
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (context, state) => const LeaderboardPage(),
      ),
      GoRoute(path: '/aura', builder: (context, state) => const AuraPage()),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const AuthGuard(child: EditProfilePage()),
      ),
      GoRoute(
        path: '/profile-public',
        builder: (context, state) {
          final userId = state.extra as String? ?? '';
          return PublicProfilePage(userId: userId);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(path: '/gbedu', builder: (context, state) => const GbeduPage()),
      GoRoute(path: '/search', builder: (context, state) => const SearchPage()),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
    ],
  );
});
