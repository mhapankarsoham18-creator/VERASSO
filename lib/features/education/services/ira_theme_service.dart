import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ira_theme_service.g.dart';

enum TimeOfDayCategory { morning, afternoon, evening, night }
enum SeasonCategory { summer, winter, monsoon, spring }

class IraThemeState {
  final String backgroundPath;
  final String outfitFolder;
  final String outfitPrefix;
  
  IraThemeState({
    required this.backgroundPath,
    required this.outfitFolder,
    required this.outfitPrefix,
  });

  String getSpritePath(String expression) {
    return 'assets/study_buddy/sprites/$outfitFolder/${outfitPrefix}_$expression.png';
  }
}

@riverpod
class IraThemeService extends _$IraThemeService {
  @override
  IraThemeState build() {
    return _calculateCurrentTheme();
  }

  void refreshTheme() {
    state = _calculateCurrentTheme();
  }

  IraThemeState _calculateCurrentTheme() {
    final now = DateTime.now();
    final TimeOfDayCategory timeOfDay = _getTimeOfDay(now);
    final SeasonCategory season = _getSeason(now);

    String backgroundPath = 'assets/study_buddy/backgrounds/study_room_day.png';
    String outfitFolder = 'Casual';
    String outfitPrefix = 'Miki_Full_Casual';

    // Morning & Afternoon
    if (timeOfDay == TimeOfDayCategory.morning || timeOfDay == TimeOfDayCategory.afternoon) {
      if (season == SeasonCategory.summer) {
        outfitFolder = 'Summer Uniform';
        outfitPrefix = 'Miki_Full_SummerUni';
        backgroundPath = 'assets/study_buddy/backgrounds/school_gym.png';
      } else if (season == SeasonCategory.winter) {
        outfitFolder = 'Winter Uniform';
        outfitPrefix = 'Miki_Full_WinterUni';
        backgroundPath = 'assets/study_buddy/backgrounds/study_room_day.png';
      } else {
        outfitFolder = 'Casual';
        outfitPrefix = 'Miki_Full_Casual';
        backgroundPath = 'assets/study_buddy/backgrounds/study_room_day.png';
      }
    } 
    // Evening
    else if (timeOfDay == TimeOfDayCategory.evening) {
      outfitFolder = 'Work';
      outfitPrefix = 'Miki_Full_Work';
      backgroundPath = 'assets/study_buddy/backgrounds/cafe_work.png';
    } 
    // Night
    else {
      outfitFolder = 'Casual';
      outfitPrefix = 'Miki_Full_Casual';
      backgroundPath = 'assets/study_buddy/backgrounds/study_room_night.png';
    }

    return IraThemeState(
      backgroundPath: backgroundPath,
      outfitFolder: outfitFolder,
      outfitPrefix: outfitPrefix,
    );
  }

  SeasonCategory _getSeason(DateTime time) {
    // Basic northern hemisphere mapping
    if (time.month >= 3 && time.month <= 5) return SeasonCategory.spring;
    if (time.month >= 6 && time.month <= 8) return SeasonCategory.summer;
    if (time.month >= 9 && time.month <= 11) return SeasonCategory.monsoon; 
    return SeasonCategory.winter;
  }

  TimeOfDayCategory _getTimeOfDay(DateTime time) {
    final hour = time.hour;
    if (hour >= 6 && hour < 12) return TimeOfDayCategory.morning;
    if (hour >= 12 && hour < 17) return TimeOfDayCategory.afternoon;
    if (hour >= 17 && hour < 20) return TimeOfDayCategory.evening;
    return TimeOfDayCategory.night;
  }
}
