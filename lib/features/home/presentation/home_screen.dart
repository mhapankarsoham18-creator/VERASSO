import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/theme/design_system.dart';
import 'package:verasso/core/ui/app_drawer.dart'; // Import Drawer
import 'package:verasso/core/ui/network_status_indicator.dart';
import 'package:verasso/widgets/notification_badge.dart';

import '../../gamification/presentation/level_up_listener.dart'; // Import LevelUpListener
import '../../learning/learning_dashboard.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../social/presentation/feed_screen.dart'; // Ensure correct import
import '../../social/presentation/search_screen.dart';
import '../../stories/presentation/story_feed_screen.dart'; // Import Story Screen

/// The main navigation hub of the application, managing top-level screens.
class HomeScreen extends StatefulWidget {
  /// Optional invite code passed during initial navigation.
  final String? inviteCode;

  /// Creates a [HomeScreen].
  const HomeScreen({super.key, this.inviteCode});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Tab content wrapped in keep-alive so switching tabs does not rebuild/dispose.
  /// Reduces jank and preserves scroll state (Phase 1.3).
  late final List<Widget> _pages = [
    _KeepAliveTab(child: const FeedScreen()),
    _KeepAliveTab(child: const DiscoverScreen()),
    _KeepAliveTab(child: const StoryFeedScreen()),
    _KeepAliveTab(child: const LearningDashboard()),
    _KeepAliveTab(child: const ProfileScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBody: true, // Allow body to go behind helper navbar
      // Sidebar for all stuffs
      drawer: const AppDrawer(),
      // We wrap the body in a way that allows us to access the drawer from internal screens if needed
      // Or just rely on the AppBar (which we might need to add or update in child screens)
      // Since child screens might have their own AppBars, they will automatically show the Hamburger menu
      // IF they are the top level of a Scaffold with a Drawer.
      // But here `HomeScreen` is the parent Scaffold. Child screens usage:
      // If child screens return Scaffold, closest ancestor Drawer is used if they don't have one.
      body: LevelUpListener(
        child: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: KeyedSubtree(
                key: ValueKey<int>(_currentIndex),
                child: _pages[_currentIndex],
              ),
            ),
            const Positioned(
              top: 40,
              right: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NotificationBadge(color: Colors.white),
                  SizedBox(width: 8),
                  NetworkStatusIndicator(),
                ],
              ),
            ),
          ],
        ),
      ),
      // Main stuff at the bottom
      bottomNavigationBar: _buildGlassNavBar(),
    );
  }

  Widget _buildGlassNavBar() {
    return Container(
      margin: const EdgeInsets.only(
          left: 16, right: 16, bottom: 20), // Lifted up slightly
      height: 70,
      decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.black.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20), // Standardized
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5))
          ]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Animate(
            effects: const [
              FadeEffect(
                  duration: DesignSystem.durationMedium,
                  curve: DesignSystem.easingStandard),
              MoveEffect(
                  begin: Offset(0, 10),
                  end: Offset.zero,
                  curve: DesignSystem.easingStandard)
            ],
            child: _NavBarItem(
                icon: LucideIcons.home,
                label: 'Home Feed',
                isSelected: _currentIndex == 0,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _currentIndex = 0);
                }),
          ),
          Animate(
            effects: [
              FadeEffect(
                  delay: 50.ms,
                  duration: DesignSystem.durationMedium,
                  curve: DesignSystem.easingStandard),
              const MoveEffect(
                  begin: Offset(0, 10),
                  end: Offset.zero,
                  curve: DesignSystem.easingStandard)
            ],
            child: _NavBarItem(
                icon: LucideIcons.compass,
                label: 'Discover',
                isSelected: _currentIndex == 1,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _currentIndex = 1);
                }),
          ),
          Animate(
            effects: [
              FadeEffect(
                  delay: 100.ms,
                  duration: DesignSystem.durationMedium,
                  curve: DesignSystem.easingStandard),
              const MoveEffect(
                  begin: Offset(0, 10),
                  end: Offset.zero,
                  curve: DesignSystem.easingStandard)
            ],
            child: _NavBarItem(
                icon: LucideIcons.camera,
                label: 'Stories',
                isSelected: _currentIndex == 2,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _currentIndex = 2);
                }),
          ),
          Animate(
            effects: [
              FadeEffect(
                  delay: 150.ms,
                  duration: DesignSystem.durationMedium,
                  curve: DesignSystem.easingStandard),
              const MoveEffect(
                  begin: Offset(0, 10),
                  end: Offset.zero,
                  curve: DesignSystem.easingStandard)
            ],
            child: _NavBarItem(
                icon: LucideIcons.graduationCap,
                label: 'Learning',
                isSelected: _currentIndex == 3,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _currentIndex = 3);
                }),
          ),
          Animate(
            effects: [
              FadeEffect(
                  delay: 200.ms,
                  duration: DesignSystem.durationMedium,
                  curve: DesignSystem.easingStandard),
              const MoveEffect(
                  begin: Offset(0, 10),
                  end: Offset.zero,
                  curve: DesignSystem.easingStandard)
            ],
            child: _NavBarItem(
                icon: LucideIcons.user,
                label: 'Profile',
                isSelected: _currentIndex == 4,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _currentIndex = 4);
                }),
          ),
        ],
      ),
    );
  }
}

/// Wraps a tab child so it is kept alive when switching tabs (Phase 1.3).
/// Avoids rebuilding Feed/Learning/Profile when user switches tabs.
class _KeepAliveTab extends StatefulWidget {
  final Widget child;

  const _KeepAliveTab({required this.child});

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem(
      {required this.icon,
      required this.label,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? Theme.of(context).colorScheme.primary
        : (Theme.of(context).brightness == Brightness.dark
            ? Colors.white54
            : Colors.black54);

    return Semantics(
      label: label,
      selected: isSelected,
      button: true,
      child: IconButton(
          onPressed: onTap,
          icon: Icon(icon, color: color, size: DesignSystem.iconSizeLarge)),
    );
  }
}
