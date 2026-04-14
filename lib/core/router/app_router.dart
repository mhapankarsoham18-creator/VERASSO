import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/signup_screen.dart';
import '../../features/auth/views/profile_setup_screen.dart';
import '../../features/home/app_shell.dart';
import '../../features/profile/views/profile_screen.dart';
import '../../features/profile/views/settings_screen.dart';
import '../../features/feed/views/feed_screen.dart' as feed_ui;
import '../../features/discovery/views/discovery_screen.dart' as discovery_ui;
import '../../features/education/views/simulations_directory.dart';
import '../../features/astronomy/views/astro_hub_screen.dart';
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/login',
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;
    final goingToAuth = state.matchedLocation == '/login' || state.matchedLocation == '/signup';

    if (!isLoggedIn && !goingToAuth) {
      return '/login';
    }
    
    if (isLoggedIn && goingToAuth) {
      // Assuming shell is the main authenticated view
      return '/shell/feed';
    }

    return null; // let them go where they were going
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/profile_setup',
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/shell/feed',
              builder: (context, state) => const feed_ui.FeedScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/shell/science',
              builder: (context, state) => const SimulationsDirectory(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/shell/astro',
              builder: (context, state) => const AstroHubScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/shell/discovery',
              builder: (context, state) => const discovery_ui.DiscoveryScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/shell/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
