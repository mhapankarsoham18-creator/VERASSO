import 'package:codemaster_odyssey/src/features/badge/data/badge_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BadgeRepository unlocks badge correctly', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Initial state: Python Pathfinder should be locked
    var badges = container.read(badgeRepositoryProvider);
    var pathfinder = badges.firstWhere((b) => b.id == 'python_pathfinder');
    expect(pathfinder.isUnlocked, false);

    // Unlock it
    container
        .read(badgeRepositoryProvider.notifier)
        .unlockBadge('python_pathfinder');

    // Verify unlocked
    badges = container.read(badgeRepositoryProvider);
    pathfinder = badges.firstWhere((b) => b.id == 'python_pathfinder');
    expect(pathfinder.isUnlocked, true);
    expect(pathfinder.unlockedAt, isNotNull);
  });
}
