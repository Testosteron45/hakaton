import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'features/profile/widgets/global_assistant_overlay.dart';
import 'shared/providers/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    runApp(MaterialApp(
      home: Scaffold(body: Center(child: Text('Firebase error: $e'))),
    ));
    return;
  }
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const KrasnodarTravelApp(),
    ),
  );
}

class KrasnodarTravelApp extends ConsumerWidget {
  const KrasnodarTravelApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Куда пойти',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        return AppViewport(
          router: router,
          child: child ?? const SizedBox.shrink(),
        );
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppViewport extends StatelessWidget {
  const AppViewport({
    super.key,
    required this.router,
    required this.child,
  });

  final GoRouter router;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RouteInformation>(
      valueListenable: router.routeInformationProvider,
      builder: (context, routeInformation, _) {
        final location = routeInformation.uri.path;
        final showAssistant = !{
          '/loading',
          '/auth',
          '/onboarding',
          '/assistant-chat',
        }.contains(location);

        return Stack(
          children: [
            child,
            if (showAssistant)
              GlobalAssistantOverlay(
                onOpenChat: () => router.push('/assistant-chat'),
              ),
          ],
        );
      },
    );
  }
}
