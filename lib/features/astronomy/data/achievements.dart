class Achievement {
  final String id;
  final String title;
  final String description;
  final String objectiveType; // 'discover_count', 'discover_specific', etc.
  final dynamic objectiveValue;
  final String emojiPath; // Just use emoji for retro vibe
  
  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.objectiveType,
    required this.objectiveValue,
    required this.emojiPath,
  });

  bool isCompleted(int totalDiscovered, List<String> discoveredNames) {
    if (objectiveType == 'discover_count') {
      return totalDiscovered >= (objectiveValue as int);
    } else if (objectiveType == 'discover_specific') {
      return discoveredNames.contains((objectiveValue as String).toLowerCase());
    } else if (objectiveType == 'discover_all_planets') {
      final planets = ['mercury', 'venus', 'mars', 'jupiter', 'saturn', 'uranus', 'neptune'];
      return planets.every((p) => discoveredNames.contains(p));
    }
    return false;
  }
}

class AchievementsData {
  static final List<Achievement> all = [
    Achievement(
      id: 'first_light',
      title: 'First Light',
      description: 'Discover your first star or planet.',
      objectiveType: 'discover_count',
      objectiveValue: 1,
      emojiPath: '🌟',
    ),
    Achievement(
      id: 'stargazer',
      title: 'Stargazer',
      description: 'Discover 10 different celestial objects.',
      objectiveType: 'discover_count',
      objectiveValue: 10,
      emojiPath: '🔭',
    ),
    Achievement(
      id: 'astronomer',
      title: 'Astronomer',
      description: 'Discover 30 different celestial objects.',
      objectiveType: 'discover_count',
      objectiveValue: 30,
      emojiPath: '🎓',
    ),
    Achievement(
      id: 'hello_neighbor',
      title: 'Hello Neighbor',
      description: 'Locate the Moon.',
      objectiveType: 'discover_specific',
      objectiveValue: 'moon',
      emojiPath: '🌕',
    ),
    Achievement(
      id: 'red_planet',
      title: 'Martian',
      description: 'Find Mars in the night sky.',
      objectiveType: 'discover_specific',
      objectiveValue: 'mars',
      emojiPath: '🔴',
    ),
    Achievement(
      id: 'system_explorer',
      title: 'System Explorer',
      description: 'Find all 7 major planets.',
      objectiveType: 'discover_all_planets',
      objectiveValue: null,
      emojiPath: '🪐',
    ),
    Achievement(
      id: 'north_star',
      title: 'Navigator',
      description: 'Locate Polaris (The North Star).',
      objectiveType: 'discover_specific',
      objectiveValue: 'polaris',
      emojiPath: '🧭',
    ),
    Achievement(
      id: 'sirius_business',
      title: 'Sirius Business',
      description: 'Find Sirius, the brightest star in the sky.',
      objectiveType: 'discover_specific',
      objectiveValue: 'sirius',
      emojiPath: '✨',
    ),
  ];
}
