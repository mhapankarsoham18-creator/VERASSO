import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/signup_screen.dart';
import '../../features/auth/views/profile_setup_screen.dart';
import '../../features/auth/views/splash_screen.dart';
import '../../features/home/app_shell.dart';
import '../../features/profile/views/profile_screen.dart';
import '../../features/profile/views/settings_screen.dart';
import '../../features/feed/views/feed_screen.dart' as feed_ui;
import '../../features/discovery/views/discovery_screen.dart' as discovery_ui;
import '../../features/education/views/simulations_directory.dart';
import '../../features/astronomy/views/astro_hub_screen_v2.dart';
import '../../features/messaging/views/conversation_list_screen.dart' as conversation_ui;
import '../../features/messaging/views/chat_screen.dart' as chat_ui;
import '../../features/messaging/views/mesh_network_screen.dart' as mesh_ui;
import '../../features/doubts/views/doubts_list_screen.dart' as doubts_ui;
import '../../features/sidequests/views/quest_board_screen.dart' as quests_ui;
import '../../features/notifications/views/notifications_screen.dart' as notifs_ui;
import '../../features/profile/views/edit_profile_screen.dart' as edit_prof_ui;
import '../../features/profile/views/privacy_settings_screen.dart' as privacy_ui;
import '../../features/education/views/ira_conversation_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;
    final goingToAuth = state.matchedLocation == '/login' || state.matchedLocation == '/signup';
    final goingToSplash = state.matchedLocation == '/splash';

    if (goingToSplash) {
      return null;
    }

    if (!isLoggedIn && !goingToAuth) {
      return '/login';
    }
    
    if (isLoggedIn && goingToAuth) {
      // Send to splash to perform profile completeness check
      return '/splash';
    }

    return null; // let them go where they were going
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => SignupScreen(),
    ),
    GoRoute(
      path: '/profile_setup',
      builder: (context, state) => ProfileSetupScreen(),
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
              builder: (context, state) => SimulationsDirectory(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/shell/astro',
              builder: (context, state) => AstroHubScreen(),
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
              builder: (context, state) => ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/ira',
      builder: (context, state) => const IraConversationScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => SettingsScreen(),
    ),
    GoRoute(
      path: '/messages',
      builder: (context, state) => const conversation_ui.ConversationListScreen(),
    ),
    GoRoute(
      path: '/messages/:id',
      builder: (context, state) {
        final Map<String, dynamic> args = state.extra as Map<String, dynamic>? ?? {};
        return chat_ui.ChatScreen(
          peerId: state.pathParameters['id'] ?? '',
          peerName: args['peerName'] ?? 'Unknown',
        );
      },
    ),
    GoRoute(
      path: '/mesh',
      builder: (context, state) => const mesh_ui.MeshNetworkScreen(),
    ),
    GoRoute(
      path: '/doubts',
      builder: (context, state) => const doubts_ui.DoubtsListScreen(),
    ),
    GoRoute(
      path: '/sidequests',
      builder: (context, state) => const quests_ui.QuestBoardScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const notifs_ui.NotificationsScreen(),
    ),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => const edit_prof_ui.EditProfileScreen(),
    ),
    GoRoute(
      path: '/privacy',
      builder: (context, state) => const privacy_ui.PrivacySettingsScreen(),
    ),
  ],
);
