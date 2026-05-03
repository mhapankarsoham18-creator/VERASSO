import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/theme/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/widgets/error_boundary.dart';
import 'core/services/app_lifecycle_guard.dart';
import 'features/messaging/services/mesh_network_service.dart';
import 'package:verasso/core/utils/logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Register lifecycle guard
  WidgetsBinding.instance.addObserver(AppLifecycleGuard.instance);
  AppLifecycleGuard.instance.registerService(MeshNetworkService());

  // Initialize Hive for Offline Data Storage
  await Hive.initFlutter();
  await Hive.openBox('feed_cache');
  await Hive.openBox('mutation_queue');
  await Hive.openBox('sidequests_cache');
  await Hive.openBox('profile_cache');

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    appLogger.d('dotenv loading error (using defaults): $e');
  }

  // Initialize Firebase explicit configuration to bypass Recaptcha anomalies
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAppCheck.instance.activate(
      // ignore: deprecated_member_use
      androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      // ignore: deprecated_member_use
      appleProvider: kReleaseMode ? AppleProvider.deviceCheck : AppleProvider.debug,
    );
  } catch (e) {
    appLogger.d('Firebase initialization pending configuration: $e');
  }

  // Initialize Supabase — dart-define (CI/CD) takes priority over .env (local dev)
  try {
    const dartDefineSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const dartDefineAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    final supabaseUrl = dartDefineSupabaseUrl.isNotEmpty
        ? dartDefineSupabaseUrl
        : (dotenv.env['SUPABASE_URL'] ?? '');
    final supabaseAnonKey = dartDefineAnonKey.isNotEmpty
        ? dartDefineAnonKey
        : (dotenv.env['SUPABASE_ANON_KEY'] ?? '');
    
    if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        accessToken: () async {
          return await FirebaseAuth.instance.currentUser?.getIdToken();
        },
      );
    }
  } catch (e) {
    appLogger.d('Supabase initialization error: $e');
  }

  // Initialize Sentry and run the app — dart-define > .env
  const dartDefineSentryDsn = String.fromEnvironment('SENTRY_DSN');
  final sentryDsn = dartDefineSentryDsn.isNotEmpty
      ? dartDefineSentryDsn
      : (dotenv.env['SENTRY_DSN'] ?? '');
  if (sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.tracesSampleRate = kDebugMode ? 1.0 : 0.1;
      },
      appRunner: () => runApp(ProviderScope(child: ErrorBoundary(child: VerassoApp()))),
    );
  } else {
    runApp(ProviderScope(child: ErrorBoundary(child: VerassoApp())));
  }
}

class VerassoApp extends ConsumerWidget {
  const VerassoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Verasso',
      theme: AppTheme.classicTheme,
      darkTheme: AppTheme.bladerunnerTheme,
      themeMode: ref.watch(themeProvider) == AppThemeType.classic ? ThemeMode.light : ThemeMode.dark,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}

