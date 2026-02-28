import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../domain/realm_model.dart';

/// A widget representing a single realm node on the Odyssey map.
class RealmNode extends StatelessWidget {
  /// The [Realm] data associated with this node.
  final Realm realm;

  /// The position index of the node in the map listing.
  final int index;

  /// Callback triggered when the node is tapped.
  final VoidCallback? onTap;

  /// Creates a [RealmNode] widget.
  const RealmNode({
    super.key,
    required this.realm,
    required this.index,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: realm.isLocked ? null : onTap,
      child: Column(
        children: [
          // Node Icon
          Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: realm.isLocked
                      ? Colors.grey.shade800
                      : const Color(0xFF6C63FF),
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (!realm.isLocked)
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.6),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: Icon(
                  realm.isLocked ? Icons.lock : Icons.code,
                  color: Colors.white,
                  size: 32,
                ),
              )
              .animate(delay: (200 * index).ms)
              .scale(duration: 400.ms, curve: Curves.easeOutBack),

          const SizedBox(height: 16),

          // Realm Name
          Text(
            realm.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ).animate(delay: (200 * index + 100).ms).fadeIn(),

          // Realm Description
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              realm.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ).animate(delay: (200 * index + 200).ms).fadeIn(),
        ],
      ),
    );
  }
}
