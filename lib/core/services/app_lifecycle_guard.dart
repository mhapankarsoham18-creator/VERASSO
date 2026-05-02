import 'package:flutter/widgets.dart';
import 'package:verasso/core/utils/logger.dart';

abstract class LifecycleAwareService {
  void onAppBackgrounded();
  void onAppResumed();
}

class AppLifecycleGuard extends WidgetsBindingObserver {
  static final AppLifecycleGuard instance = AppLifecycleGuard._internal();
  
  AppLifecycleGuard._internal();

  final List<LifecycleAwareService> _services = [];

  void registerService(LifecycleAwareService service) {
    if (!_services.contains(service)) {
      _services.add(service);
    }
  }

  void unregisterService(LifecycleAwareService service) {
    _services.remove(service);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      appLogger.d('AppLifecycleGuard: App going to BACKGROUND. Broadcasting to services...');
      for (var service in _services) {
        service.onAppBackgrounded();
      }
    } else if (state == AppLifecycleState.resumed) {
      appLogger.d('AppLifecycleGuard: App RESUMED to FOREGROUND. Broadcasting to services...');
      for (var service in _services) {
        service.onAppResumed();
      }
    }
  }
}

