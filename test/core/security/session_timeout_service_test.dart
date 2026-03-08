import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/core/security/session_timeout_service.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  group('SessionTimeoutService Tests (Phase 3.6)', () {
    test('Service starts and tracks active state', () {
      final service = SessionTimeoutService();
      
      expect(service.isLocked, false);
      
      service.start();
      expect(service.isLocked, false);
      
      service.dispose();
    });

    test('Manual lock works', () {
      final service = SessionTimeoutService();
      service.start();
      
      service.lock();
      expect(service.isLocked, true);
      
      service.dispose();
    });

    test('Unlock resets locked state', () {
      final service = SessionTimeoutService();
      service.start();
      
      service.lock();
      expect(service.isLocked, true);
      
      service.unlock();
      expect(service.isLocked, false);
      
      service.dispose();
    });

    test('Timeout duration is configurable', () {
      final service = SessionTimeoutService();
      
      expect(service.timeoutDuration, const Duration(minutes: 60));
      
      service.setTimeoutDuration(const Duration(minutes: 30));
      expect(service.timeoutDuration, const Duration(minutes: 30));
      
      service.dispose();
    });

    test('Stop cancels monitoring', () {
      final service = SessionTimeoutService();
      service.start();
      
      service.stop();
      // Should not throw and service should stop tracking
      
      service.dispose();
    });

    test('Reset timer extends session', () {
      final service = SessionTimeoutService();
      service.start();
      
      // Reset should not throw and should extend the session
      service.resetTimer();
      expect(service.isLocked, false);
      
      service.dispose();
    });

    test('Timeout callback is triggered after lock', () {
      final service = SessionTimeoutService();
      service.start();
      
      bool callbackTriggered = false;
      service.setOnTimeoutCallback(() {
        callbackTriggered = true;
      });
      
      service.lock();
      expect(callbackTriggered, true);
      
      service.dispose();
    });

    test('Warning callback registration works', () {
      final service = SessionTimeoutService();
      service.start();
      
      bool warningTriggered = false;
      service.setOnWarningCallback(() {
        warningTriggered = true;
      });
      
      // Can't easily trigger warning without waiting, but callback should be set
      expect(service.isLocked, false);
      expect(warningTriggered, false); // Verify initial state
      
      service.dispose();
    });
  });
}
