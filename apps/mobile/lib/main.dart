import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app/router/app_router.dart';
import 'package:mobile/core/backend/backend_config.dart';
import 'package:mobile/core/backend/supabase_client.dart';
import 'package:mobile/core/theme/ora_theme.dart';
import 'package:mobile/core/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Logger.enabled = kDebugMode;
  await BackendConfig.load();
  await SupabaseClientProvider.initialize();

  if (kDebugMode && SupabaseClientProvider.isInitialized) {
    _debugCheckAuthProfileSync();
  }

  runApp(const ProviderScope(child: MyApp()));
}

void _debugCheckAuthProfileSync() {
  try {
    final session = SupabaseClientProvider.client!.auth.currentSession;
    final authUser = session?.user;

    if (authUser != null) {
      SupabaseClientProvider.client!
          .from('profiles')
          .select('user_id')
          .eq('user_id', authUser.id)
          .maybeSingle()
          .then((profile) {
            if (profile == null) {
              Logger.warning(
                'Auth session exists but no matching profile was found. '
                'This may indicate a database trigger issue or RLS policy problem.',
                tag: 'DebugCheck',
              );
            }
          })
          .catchError((error) {
            Logger.error(
              'Failed to check profile existence for the current auth session',
              error: error,
              tag: 'DebugCheck',
            );
          });
    }
  } catch (e) {
    Logger.error('Debug check failed', error: e, tag: 'DebugCheck');
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(oraThemeModeProvider);

    return MaterialApp.router(
      title: 'ORA',
      theme: ORATheme.light(),
      darkTheme: ORATheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
