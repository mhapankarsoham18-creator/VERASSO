import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/error_view.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../data/relationship_repository.dart';
import 'relationship_controller.dart';
import 'user_profile_screen.dart';

/// Provider for the list of friends (confirmed relationships).
final friendsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(relationshipRepositoryProvider).getFriends();
});

/// Provider for the list of pending incoming friend requests.
final pendingRequestsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(relationshipRepositoryProvider).getPendingRequests();
});

/// Screen displaying the user's social network, including friends and pending requests.
class FriendsListScreen extends ConsumerStatefulWidget {
  /// Creates a [FriendsListScreen] instance.
  const FriendsListScreen({super.key});

  @override
  ConsumerState<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends ConsumerState<FriendsListScreen> {
  @override
  Widget build(BuildContext context) {
    // In a real implementation we would fetch relationships via a repository method
    // For now, let's assume we can query them.

    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      body: LiquidBackground(
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'My Friends'),
                  Tab(text: 'Pending'),
                ],
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildFriendsTab(),
                    _buildPendingTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriendsTab() {
    final friendsAsync = ref.watch(friendsProvider);

    return friendsAsync.when(
      data: (friends) {
        if (friends.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.users, size: 64, color: Colors.white24),
                const SizedBox(height: 16),
                const Text('You have no friends yet.',
                    style: TextStyle(color: Colors.white54)),
                const SizedBox(height: 8),
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Find New Connections'))
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final rel = friends[index];
            final profile = rel['profiles'];
            return GlassContainer(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: profile['avatar_url'] != null
                      ? NetworkImage(profile['avatar_url'])
                      : null,
                  child: profile['avatar_url'] == null
                      ? const Icon(LucideIcons.user)
                      : null,
                ),
                title: Text(profile['full_name'] ?? 'User',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('@${profile['username']}'),
                trailing:
                    const Icon(LucideIcons.chevronRight, color: Colors.white54),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          UserProfileScreen(userId: profile['id'])));
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(friendsProvider),
      ),
    );
  }

  Widget _buildPendingTab() {
    final requestsAsync = ref.watch(pendingRequestsProvider);

    return requestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.userPlus, size: 64, color: Colors.white24),
                SizedBox(height: 16),
                Text('No pending requests.',
                    style: TextStyle(color: Colors.white54)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final rel = requests[index];
            final profile = rel['profiles'];
            return GlassContainer(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: profile['avatar_url'] != null
                      ? NetworkImage(profile['avatar_url'])
                      : null,
                  child: profile['avatar_url'] == null
                      ? const Icon(LucideIcons.user)
                      : null,
                ),
                title: Text(profile['full_name'] ?? 'User',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('@${profile['username']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.check, color: Colors.green),
                      onPressed: () async {
                        HapticFeedback.mediumImpact();
                        await ref
                            .read(relationshipControllerProvider.notifier)
                            .acceptRequest(profile['id']);
                        ref.invalidate(friendsProvider);
                        ref.invalidate(pendingRequestsProvider);
                      },
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, color: Colors.red),
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        await ref
                            .read(relationshipControllerProvider.notifier)
                            .unfriendOrCancel(profile['id']);
                        ref.invalidate(pendingRequestsProvider);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(pendingRequestsProvider),
      ),
    );
  }
}
