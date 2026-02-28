import 'package:animations/animations.dart';
import 'package:codemaster_odyssey/codemaster_odyssey.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/monitoring/app_logger.dart';
import 'core/monitoring/bug_report_dialog.dart';
import 'core/monitoring/sentry_service.dart';
import 'core/security/mobile_security_service.dart';
import 'core/security/security_initializer.dart';
import 'core/security/session_timeout_service.dart';
import 'core/services/background_sync_manager.dart';
import 'core/services/mesh_power_manager.dart';
import 'core/services/mesh_sync_manager.dart';
import 'core/services/offline_storage_service.dart';
import 'core/services/supabase_service.dart';
import 'core/services/sync_bridge_service.dart';
import 'core/theme/app_theme.dart';
import 'core/ui/route_error_screen.dart';
import 'core/ui/secrecy_filter.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/auth_screen.dart';
import 'features/auth/presentation/screen_lock_overlay.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/learning/presentation/cognitive_dashboard.dart';
import 'features/messaging/presentation/group_chat_screen.dart';
import 'features/news/presentation/article_detail_screen.dart';
import 'features/notifications/data/notification_service.dart';
import 'features/settings/presentation/privacy_settings_controller.dart';
import 'features/settings/presentation/theme_controller.dart';
import 'features/social/presentation/post_detail_screen.dart';
import 'features/support/presentation/feedback_screen.dart';
import 'l10n/app_localizations.dart';

// Sentry configuration is managed via SentryService.
// Provide SENTRY_DSN via --dart-define for production builds.

/// The application entry point.
///
/// Initializes Sentry, Supabase, Firebase, security services, offline storage,
/// background sync, mesh networking, and notifications before running
/// the [VerassoApp].
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize with Sentry error reporting
  await SentryService.initialize(
    appRunner: () async {
      // Initialize shared preferences
      final prefs = await SharedPreferences.getInstance();

      // Check for Compromised Device
      final isCompromised = await MobileSecurityService().isDeviceCompromised();
      if (isCompromised) {
        SentryService.addBreadcrumb(
          message: 'Device appears to be Jailbroken or Rooted',
          category: 'security',
          level: SentryLevel.warning,
        );
        // Security: Block access on compromised devices
        runApp(const CompromisedDeviceApp());
        return;
      }

      // Initialize Supabase (with Pinned Http Client)
      await SupabaseService.initialize();

      // Initialize Firebase (Graceful failure if config missing)
      try {
        await Firebase.initializeApp();
        FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );

        final messaging = FirebaseMessaging.instance;
        await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      } catch (e, stack) {
        AppLogger.error('Firebase initialization failed', error: e);
        SentryService.captureException(e, stackTrace: stack);
      }

      // Initialize Security Services (Auth, Encryption, Biometric)
      await SecurityInitializer.initialize();

      // Initialize Offline Storage
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          // Odyssey Backend Overrides
          odysseySupabaseClientProvider
              .overrideWithValue(SupabaseService.client),
          odysseyUserIdProvider
              .overrideWith((ref) => ref.watch(currentUserProvider)?.id),
        ],
      );
      await container
          .read(offlineStorageServiceProvider)
          .initialize(SecurityInitializer.encryptionService);

      // Initialize Background Sync Manager
      container.read(backgroundSyncManagerProvider);

      // Initialize Mesh Sync Manager
      container.read(meshSyncManagerProvider);

      // Initialize Mesh Power Manager (Adaptive Duty Cycle)
      container.read(meshPowerManagerProvider);

      // Initialize Notification Service (FCM & Local)
      await container.read(notificationServiceProvider).initializeFCM();

      // Initialize Sync Bridge (Mesh <-> Cloud)
      container.read(syncBridgeServiceProvider);

      runApp(
        UncontrolledProviderScope(
          container: container,
          child: const VerassoApp(),
        ),
      );
    },
    environment: const String.fromEnvironment(
      'ENV',
      defaultValue: 'development',
    ),
  );
}

/// Provider for the application's [GoRouter] instance.
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: kDebugMode,
    observers: [SentryNavigatorObserver()],
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AuthScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.horizontal,
            child: child,
          ),
        ),
      ),
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.horizontal,
            child: child,
          ),
        ),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const AuthScreen(showResetView: true),
      ),
      GoRoute(
        path: '/invite/:code',
        builder: (context, state) =>
            HomeScreen(inviteCode: state.pathParameters['code']),
      ),
      GoRoute(
        path: '/dashboard/cognitive',
        builder: (context, state) => const CognitiveDashboard(),
      ),
      GoRoute(
        path: '/post/:id',
        builder: (context, state) =>
            PostDetailScreen(postId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/news/:id',
        builder: (context, state) =>
            ArticleDetailScreen(articleId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/feedback',
        builder: (context, state) => const FeedbackScreen(),
      ),
      GoRoute(
        path: '/group-chat/:groupId/:name',
        builder: (context, state) => GroupChatScreen(
          groupId: state.pathParameters['groupId']!,
          groupName: state.pathParameters['name']!,
        ),
      ),
    ],
    errorBuilder: (context, state) => RouteErrorScreen(state: state),
    redirect: (context, state) {
      final isLoggedIn = authState.asData?.value != null;
      final isLoggingIn = state.uri.toString() == '/login';
      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/';

      return null;
    },
  );
});

/// Displays a security warning when the device is detected as compromised.
class CompromisedDeviceApp extends StatelessWidget {
  /// Creates a [CompromisedDeviceApp].
  const CompromisedDeviceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
      ],
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Builder(
              builder: (context) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.shield, color: Colors.red, size: 64),
                    const SizedBox(height: 24),
                    Text(
                      AppLocalizations.of(context)?.securityAlert ??
                          'Security Alert',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)?.deviceCompromisedBody ??
                          'This device appears to be compromised (rooted/jailbroken).\n\nFor your security, Verasso cannot run in this environment.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// The root widget of the Verasso application.
class VerassoApp extends ConsumerStatefulWidget {
  /// Creates the [VerassoApp] widget.
  const VerassoApp({super.key});

  @override
  ConsumerState<VerassoApp> createState() => _VerassoAppState();
}

class _VerassoAppState extends ConsumerState<VerassoApp>
    with WidgetsBindingObserver {
  AppLifecycleState _lastState = AppLifecycleState.resumed;

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeState = ref.watch(themeControllerProvider);
    final authState = ref.watch(authStateProvider);
    final privacySettings = ref.watch(privacySettingsProvider);
    final isLoggedIn = authState.asData?.value != null;

    // Handle Session Timeout Activation
    ref.listen(authStateProvider, (previous, next) {
      final loggedIn = next.asData?.value != null;
      if (loggedIn) {
        final timeoutService = ref.read(sessionTimeoutProvider);
        timeoutService.start();
        timeoutService.setTimeoutDuration(privacySettings.sessionTimeout);

        // Sync user to Sentry
        SentryService.syncUserFromSupabase();

        // Wire secure logout/lock
        timeoutService.setOnTimeoutCallback(() {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.sessionExpired),
            ),
          );
          // ScreenLockOverlay listens to timeoutService.isLocked
        });

        timeoutService.setOnWarningCallback(() {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(AppLocalizations.of(context)!.sessionWarning),
              content: Text(AppLocalizations.of(context)!.sessionExpireBody),
              actions: [
                TextButton(
                  onPressed: () {
                    timeoutService.resetTimer();
                    Navigator.pop(context);
                  },
                  child: Text(AppLocalizations.of(context)!.stayLoggedIn),
                ),
              ],
            ),
          );
        });
      } else {
        ref.read(sessionTimeoutProvider).stop();
      }
    });

    // Update timeout duration when settings change
    ref.listen<PrivacySettings>(privacySettingsProvider, (previous, next) {
      if (previous != null && next.sessionTimeout != previous.sessionTimeout) {
        ref
            .read(sessionTimeoutProvider)
            .setTimeoutDuration(next.sessionTimeout);
      }
    });

    final isBackgrounded = privacySettings.autoBlurInBackground &&
        _lastState != AppLifecycleState.resumed;

    return Listener(
      onPointerDown: (_) {
        if (isLoggedIn) {
          ref.read(sessionTimeoutProvider).resetTimer();
        }
      },
      child: SecrecyFilter(
        isContentVisible: !isBackgrounded,
        child: MaterialApp.router(
          title: 'Verasso',
          theme: AppTheme.lightTheme(
            themeState.primaryColor,
            themeState.accentColor,
          ),
          darkTheme: AppTheme.darkTheme(
            themeState.primaryColor,
            themeState.accentColor,
          ),
          themeMode: themeState.mode,
          locale: themeState.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),
          ],
          routerConfig: router,
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            if (!isLoggedIn) return child!;
            return Stack(
              children: [
                ScreenLockOverlay(child: child!),

                // Global Bug Catcher FAB (debug-only)
                if (kDebugMode)
                  Positioned(
                    bottom: 100,
                    right: 16,
                    child: Material(
                      type: MaterialType.transparency,
                      child: FloatingActionButton(
                        heroTag: 'bug_catcher_fab',
                        mini: true,
                        backgroundColor: Colors.orangeAccent.withValues(
                          alpha: 0.8,
                        ),
                        foregroundColor: Colors.black,
                        child: const Icon(LucideIcons.shieldAlert, size: 20),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => const BugReportDialog(),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() => _lastState = state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }
}
