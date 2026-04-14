import 'package:hive_flutter/hive_flutter.dart';

/// Hive-cached record of celestial objects the user has discovered.
class DiscoveryLog {
  static const _boxName = 'astro_discoveries';
  Box? _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  /// Mark an object as discovered.
  void discover(String objectName) {
    if (_box == null) return;
    final key = objectName.toLowerCase();
    final existing = _box!.get(key) as Map?;
    if (existing == null) {
      _box!.put(key, {
        'name': objectName,
        'discoveredAt': DateTime.now().toIso8601String(),
        'timesViewed': 1,
      });
    } else {
      final updated = Map<String, dynamic>.from(existing);
      updated['timesViewed'] = (updated['timesViewed'] as int? ?? 0) + 1;
      _box!.put(key, updated);
    }
  }

  /// Check if an object has been discovered.
  bool isDiscovered(String objectName) {
    if (_box == null) return false;
    return _box!.containsKey(objectName.toLowerCase());
  }

  /// Total number of unique objects discovered.
  int get discoveredCount {
    if (_box == null) return 0;
    return _box!.length;
  }

  /// All discovered object names.
  List<String> get discoveredNames {
    if (_box == null) return [];
    return _box!.keys.cast<String>().toList();
  }
}
