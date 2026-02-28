import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/gamification/presentation/achievements_screen.dart';
import '../../features/gamification/presentation/leaderboard_screen.dart';
import '../../features/learning/presentation/classroom/mesh_labs_screen.dart';
import '../../features/learning/presentation/physics/physics_menu_screen.dart';
import '../../features/messaging/presentation/chats_screen.dart';
import '../../features/news/presentation/news_screen.dart';
import '../../features/notifications/data/notification_service.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/presentation/profile_controller.dart';
import '../../features/recommendations/presentation/for_you_screen.dart';
import '../../features/settings/presentation/help_support_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/social/presentation/friends_list_screen.dart';
import '../../features/social/presentation/saved_posts_screen.dart';
import '../../features/support/presentation/feedback_screen.dart';
import '../../l10n/app_localizations.dart';
import '../config/app_config.dart';
import 'glass_container.dart';

/// a futuristic, semi-transparent navigation drawer that provides access to all major app features.
///
/// It uses a [GlassContainer] to create a "Liquid Glass" effect and integrates
/// with both [userProfileProvider] for header data and [unreadNotificationCountProvider] for badges.
class AppDrawer extends ConsumerWidget {
  /// Creates an [AppDrawer].
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Drawer(
      backgroundColor: Colors.transparent, // Important for glass effect
      child: GlassContainer(
        borderRadius: const BorderRadius.only(
            topRight: Radius.circular(30), bottomRight: Radius.circular(30)),
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            const SizedBox(height: 50),
            // Header
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ref.watch(userProfileProvider).when(
                    data: (profile) => Row(
                      children: [
                        ClipOval(
                          child: profile?.avatarUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: profile!.avatarUrl!,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      Shimmer.fromColors(
                                    baseColor: Colors.white10,
                                    highlightColor: Colors.white24,
                                    child: Container(color: Colors.white),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const Icon(LucideIcons.user,
                                          color: Colors.white, size: 30),
                                )
                              : Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.white10,
                                  child: const Icon(LucideIcons.user,
                                      color: Colors.white, size: 30),
                                ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(profile?.displayName ?? l10n.verassoUser,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis),
                              Text(
                                  '@${profile?.username ?? l10n.defaultUsername}',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 14),
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        )
                      ],
                    ),
                    loading: () => Shimmer.fromColors(
                      baseColor: Colors.white10,
                      highlightColor: Colors.white24,
                      child: Row(
                        children: [
                          const CircleAvatar(radius: 30),
                          const SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                  width: 100, height: 15, color: Colors.white),
                              const SizedBox(height: 5),
                              Container(
                                  width: 60, height: 12, color: Colors.white),
                            ],
                          )
                        ],
                      ),
                    ),
                    error: (_, __) => const Icon(LucideIcons.user),
                  ),
            ),
            const Divider(color: Colors.white24),
            // Menu Items
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                children: [
                  _DrawerItem(
                      icon: LucideIcons.users,
                      title: l10n.community,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const FriendsListScreen()));
                      }),
                  _DrawerItem(
                      icon: LucideIcons.bell,
                      title: l10n.notifications,
                      trailing: ref.watch(unreadNotificationCountProvider).when(
                            data: (count) => count > 0
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: Colors.redAccent,
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: Text('$count',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                  )
                                : null,
                            loading: () => null,
                            error: (_, __) => null,
                          ),
                      onTap: () {
                        Navigator.pop(context); // Close drawer
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const NotificationsScreen()));
                      }),
                  _DrawerItem(
                      icon: LucideIcons.sparkles,
                      title: l10n.forYou,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ForYouScreen()));
                      }),
                  if (AppConfig.enableBetaModules)
                    _DrawerItem(
                        icon: LucideIcons.palette,
                        title: l10n.talentShowcase,
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('BETA',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orangeAccent)),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('🎨 Talent Showcase coming soon!'),
                                duration: Duration(seconds: 2)),
                          );
                        }),
                  _DrawerItem(
                      icon: LucideIcons.messageCircle,
                      title: l10n.messages,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ChatsScreen()));
                      }),
                  _DrawerItem(
                      icon: LucideIcons.bookmark,
                      title: l10n.savedContent,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SavedPostsScreen()));
                      }),
                  _DrawerItem(
                      icon: LucideIcons.testTube,
                      title: l10n.physicsLab,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PhysicsMenuScreen()));
                      }),
                  if (AppConfig.enableBetaModules)
                    _DrawerItem(
                        icon: LucideIcons.calculator,
                        title: l10n.financeHub,
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('BETA',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orangeAccent)),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('💰 Finance Hub coming soon!'),
                                duration: Duration(seconds: 2)),
                          );
                        }),
                  const Divider(color: Colors.white24, height: 30),
                  _DrawerItem(
                      icon: LucideIcons.award,
                      title: l10n.achievements,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AchievementsScreen()));
                      }),
                  _DrawerItem(
                      icon: LucideIcons.trophy,
                      title: l10n.leaderboard,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LeaderboardScreen()));
                      }),
                  _DrawerItem(
                      icon: LucideIcons.newspaper,
                      title: l10n.newsFeed,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const NewsScreen()));
                      }),
                  _DrawerItem(
                      icon: LucideIcons.presentation,
                      title: l10n.classroomLabs,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const MeshLabsScreen()));
                      }),
                  const Divider(color: Colors.white24, height: 30),
                  _DrawerItem(
                      icon: LucideIcons.settings,
                      title: l10n.settings,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SettingsScreen()));
                      }),
                  _DrawerItem(
                      icon: LucideIcons.helpCircle,
                      title: l10n.helpAndSupport,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const HelpSupportScreen()));
                      }),
                  _DrawerItem(
                      icon: LucideIcons.messageSquare,
                      title: 'Beta Feedback',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('NEW',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.greenAccent)),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const FeedbackScreen()));
                      }),
                ],
              ),
            ),
            // Footer
            const Divider(color: Colors.white24),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: _DrawerItem(
                  icon: LucideIcons.logOut,
                  title: l10n.signOut,
                  textColor: Colors.redAccent,
                  iconColor: Colors.redAccent,
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(authControllerProvider.notifier).signOut();
                  }),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// A private helper widget for rendering individual menu items in the [AppDrawer].
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;
  final Widget? trailing;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.textColor,
    this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.white, size: 24),
      title: Text(title,
          style: TextStyle(color: textColor ?? Colors.white, fontSize: 16)),
      trailing: trailing,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      hoverColor: Colors.white.withValues(alpha: 0.1),
    );
  }
}
