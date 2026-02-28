import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/services/geospatial_discovery_service.dart';
import 'package:verasso/core/widgets/empty_state_widget.dart';
import 'package:verasso/features/auth/presentation/auth_controller.dart';
import 'package:verasso/features/messaging/presentation/chat_detail_screen.dart';

/// A screen that displays nearby explorers using geospatial discovery.
class NearbyUsersScreen extends ConsumerStatefulWidget {
  /// Creates a [NearbyUsersScreen] instance.
  const NearbyUsersScreen({super.key});

  @override
  ConsumerState<NearbyUsersScreen> createState() => _NearbyUsersScreenState();
}

class _NearbyUsersScreenState extends ConsumerState<NearbyUsersScreen> {
  List<Map<String, dynamic>> _nearbyUsers = [];
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Explorers'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: _refreshNearby,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _nearbyUsers.isEmpty
              ? const EmptyStateWidget(
                  icon: LucideIcons.users,
                  title: 'No one nearby',
                  message:
                      'Try moving to a more active area or check back later.',
                )
              : ListView.builder(
                  itemCount: _nearbyUsers.length,
                  itemBuilder: (context, index) {
                    final user = _nearbyUsers[index];
                    final distance = user['dist_meters'] != null
                        ? (user['dist_meters'] / 1000).toStringAsFixed(1)
                        : '?';

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(user['full_name']?[0] ?? 'U'),
                      ),
                      title: Text(user['full_name'] ?? 'Unknown Explorer'),
                      subtitle: Text('$distance km away'),
                      trailing: IconButton(
                        icon: const Icon(LucideIcons.messageSquare),
                        onPressed: () {
                          final myId = ref.read(currentUserProvider)?.id;
                          if (myId == null) return;
                          final otherId = user['id'] as String;
                          final parts = [myId, otherId]..sort();
                          final convId = 'conv_${parts.join('_')}';

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatDetailScreen(
                                conversationId: convId,
                                otherUserId: otherId,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }

  @override
  void initState() {
    super.initState();
    _refreshNearby();
  }

  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _refreshNearby() async {
    setState(() => _isLoading = true);

    try {
      final position = await _determinePosition();
      final geo = ref.read(geospatialDiscoveryServiceProvider);

      // Update current user's location in DB
      await geo.updateMyLocation(position.latitude, position.longitude);

      // Find nearby users using real coordinates
      final users = await geo.findNearbyUsers(
        lat: position.latitude,
        lng: position.longitude,
      );

      if (mounted) {
        setState(() {
          _nearbyUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location error: ${e.toString()}')),
        );
      }
    }
  }
}
