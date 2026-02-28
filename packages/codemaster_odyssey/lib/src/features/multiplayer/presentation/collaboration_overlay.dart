import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mesh_sync_repository.dart';
import '../domain/peer_model.dart';

/// An overlay widget that displays MESH peers and collaboration status.
class CollaborationOverlay extends ConsumerWidget {
  /// Creates a [CollaborationOverlay] instance.
  const CollaborationOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peers = ref.watch(meshSyncProvider);

    return Positioned(
      bottom: 20,
      right: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'MESH MENTORS',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(children: peers.map((peer) => _PeerAvatar(peer: peer)).toList()),
        ],
      ),
    );
  }
}

class _PeerAvatar extends StatelessWidget {
  final Peer peer;

  const _PeerAvatar({required this.peer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Tooltip(
        message: '${peer.name} (${peer.activeRealm})',
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF00E5FF), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                blurRadius: 10,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF2D2D44),
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: 20,
            ), // Placeholder for real asset
          ),
        ),
      ).animate().scale(duration: 500.ms).fadeIn(),
    );
  }
}
