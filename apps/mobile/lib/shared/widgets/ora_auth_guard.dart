import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/features/session/session_provider.dart';
import 'package:mobile/shared/widgets/ora_loading_indicator.dart';

/// ORA Auth Guard
///
/// A reusable widget that wraps protected pages.
///
/// - Detects expired sessions and redirects to `/auth`.
/// - Shows a loading indicator while the session is being restored.
/// - Renders the child widget only when the user is authenticated.
///
/// Usage:
/// ```dart
/// AuthGuard(
///   child: MyProtectedPage(),
/// )
/// ```
class AuthGuard extends ConsumerWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(sessionProvider);
    final brightness = Theme.of(context).brightness;

    // Loading state — show a loading indicator while session restores.
    if (sessionState.isLoading) {
      return Scaffold(
        backgroundColor: ORAColors.background(brightness),
        body: const Center(
          child: ORALoadingIndicator(),
        ),
      );
    }

    // Error state — treat as unauthenticated and redirect.
    if (sessionState.hasError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go('/auth');
        }
      });
      return Scaffold(
        backgroundColor: ORAColors.background(brightness),
        body: const Center(
          child: ORALoadingIndicator(),
        ),
      );
    }

    // Unauthenticated — redirect to auth.
    final user = sessionState.value;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go('/auth');
        }
      });
      return Scaffold(
        backgroundColor: ORAColors.background(brightness),
        body: const Center(
          child: ORALoadingIndicator(),
        ),
      );
    }

    // Authenticated — render the protected page.
    return child;
  }
}