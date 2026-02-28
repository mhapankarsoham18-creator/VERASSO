import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/realm_model.dart';

/// Provider for the [RealmRepository] instance.
final realmRepositoryProvider = Provider((ref) => RealmRepository());

/// Repository responsible for providing the list of available realms.
class RealmRepository {
  /// Returns a list of all [Realm]s in the Odyssey.
  List<Realm> getRealms() {
    return [
      Realm(
        id: '1',
        name: 'Python Plains',
        description: 'Begin your journey with the clear syntax of Python.',
        isLocked: false,
        progress: 0.1,
      ),
      Realm(
        id: '2',
        name: 'JavaScript Jungles',
        description: 'Navigate the wild and asynchronous world of the web.',
        isLocked: true,
      ),
      Realm(
        id: '3',
        name: 'Dart Dunes',
        description: 'Master the art of UI crafting in the shifting sands.',
        isLocked: true,
      ),
      // Add more realms as needed
    ];
  }
}
