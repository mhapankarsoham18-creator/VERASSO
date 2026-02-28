import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:verasso/core/ui/glass_container.dart';

import '../../../widgets/animations/badge_unlock_animation.dart';
import '../models/badge_model.dart' as model;

/// A dialog that displays detailed information about a specific badge,
/// including its name, rarity, description, and an unlock animation.
class AchievementDetailDialog extends StatelessWidget {
  /// The badge model instance to display.
  final model.Badge badge;

  /// Whether the user has unlocked this badge.
  final bool isUnlocked;

  /// The timestamp when the badge was unlocked, if applicable.
  final DateTime? unlockedAt;

  /// Creates an [AchievementDetailDialog] instance.
  const AchievementDetailDialog({
    super.key,
    required this.badge,
    required this.isUnlocked,
    this.unlockedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassContainer(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animation or Icon
            SizedBox(
              height: 150,
              width: 150,
              child: isUnlocked
                  ? BadgeUnlockAnimation(
                      badgeName: badge.name,
                      badgeDescription: badge.description,
                      rarity: badge.rarity.name.toLowerCase(),
                      category: badge.category.name.toLowerCase(),
                      pointsReward: badge.requiredPoints,
                      onComplete: () {},
                    )
                  : Opacity(
                      opacity: 0.3,
                      child: Center(
                        child: _buildBadgeIcon(badge.icon),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              badge.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getRarityColor(badge.rarity).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getRarityColor(badge.rarity)),
              ),
              child: Text(
                badge.rarity.name.toUpperCase(),
                style: TextStyle(
                  color: _getRarityColor(badge.rarity),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              badge.description,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (isUnlocked && unlockedAt != null)
              Text(
                'Earned on ${_formatDate(unlockedAt!)}',
                style: const TextStyle(color: Colors.greenAccent, fontSize: 14),
              )
            else
              const Text(
                'Keep playing to unlock!',
                style: TextStyle(
                    color: Colors.white38,
                    fontSize: 14,
                    fontStyle: FontStyle.italic),
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!isUnlocked)
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to relevant feature based on badge category
                      String message = 'Focus on completing more simulations!';
                      if (badge.category == model.BadgeCategory.explorer) {
                        message =
                            'Tip: Explore the Astronomy Hub and AR views.';
                      } else if (badge.category ==
                          model.BadgeCategory.subject) {
                        message =
                            'Tip: Complete chapters in your enrolled courses.';
                      } else if (badge.category == model.BadgeCategory.social) {
                        message =
                            'Tip: Connect with more friends and join study groups.';
                      }

                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(message)));

                      // In a full production app, this would use context.push() to the specific lab.
                    },
                    icon:
                        const Icon(LucideIcons.lightbulb, color: Colors.amber),
                    label: const Text('Hint',
                        style: TextStyle(color: Colors.amber)),
                  ),
                ElevatedButton.icon(
                  onPressed: () async {
                    // ignore: deprecated_member_use
                    await Share.share(
                        'I just unlocked the ${badge.name} badge on Verasso! 🚀\n${badge.description}');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.withValues(alpha: 0.2),
                    foregroundColor: Colors.blueAccent,
                  ),
                  icon: const Icon(LucideIcons.share2, size: 18),
                  label: const Text('Share'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeIcon(String iconStr) {
    if (iconStr.length < 5) {
      return Text(iconStr, style: const TextStyle(fontSize: 80));
    }

    if (iconStr == 'first_steps') return _buildWalkingAnimation();
    if (iconStr == 'scholar') return _buildBookFlipAnimation();
    if (iconStr == 'master_builder') return _buildHammerAnimation();
    if (iconStr == '100_club') {
      return _buildCountingAnimation();
    }
    if (iconStr == 'week_warrior') {
      return _buildFlameAnimation();
    }

    IconData iconData;
    switch (iconStr) {
      case 'school':
        iconData = Icons.school;
        break;
      case 'science':
        iconData = Icons.science;
        break;
      case 'biotech':
        iconData = Icons.biotech;
        break;
      case 'explore':
        iconData = Icons.explore;
        break;
      case 'auto_awesome':
        iconData = Icons.auto_awesome;
        break;
      case 'architecture':
        iconData = Icons.architecture;
        break;
      case 'local_fire_department':
        iconData = Icons.local_fire_department;
        break;
      case 'today':
        iconData = Icons.today;
        break;
      case 'menu_book':
        iconData = Icons.menu_book;
        break;
      case 'construction':
        iconData = Icons.construction;
        break;
      case 'attach_money':
        iconData = Icons.attach_money;
        break;
      case 'groups':
        iconData = Icons.groups;
        break;
      default:
        iconData = Icons.emoji_events;
    }

    return Icon(iconData, size: 80, color: Colors.white);
  }

  Widget _buildBookFlipAnimation() {
    return const Icon(LucideIcons.bookOpen, size: 80, color: Colors.blueAccent);
  }

  Widget _buildCountingAnimation() {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: 100),
      duration: const Duration(seconds: 2),
      builder: (context, value, child) {
        return Text(
          '$value',
          style: const TextStyle(
            fontSize: 60,
            fontWeight: FontWeight.bold,
            color: Colors.amber,
          ),
        );
      },
    );
  }

  Widget _buildFlameAnimation() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.2),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: const Icon(LucideIcons.flame,
              size: 80, color: Colors.deepOrangeAccent),
        );
      },
    );
  }

  Widget _buildHammerAnimation() {
    return const Icon(LucideIcons.wrench, size: 80, color: Colors.brown);
  }

  Widget _buildWalkingAnimation() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -0.2, end: 0.2),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      builder: (context, val, child) {
        return Transform.rotate(
          angle: val,
          child: const Icon(LucideIcons.footprints,
              size: 80, color: Colors.orangeAccent),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getRarityColor(model.BadgeRarity rarity) {
    switch (rarity) {
      case model.BadgeRarity.common:
        return Colors.grey;
      case model.BadgeRarity.rare:
        return Colors.blue;
      case model.BadgeRarity.epic:
        return Colors.purple;
      case model.BadgeRarity.legendary:
        return Colors.orange;
    }
  }
}
