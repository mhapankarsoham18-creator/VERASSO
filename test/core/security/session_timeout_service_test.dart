import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/core/security/session_timeout_service.dart';

void main() {
  group('SessionTimeoutService Tests', () {
    testWidgets('starts as unlocked and inactive', (WidgetTester tester) async {
      final service = SessionTimeoutService();
      expect(service.isLocked, isFalse);
    });

    testWidgets('lock() sets isLocked to true', (WidgetTester tester) async {
      final service = SessionTimeoutService();
      service.lock();
      expect(service.isLocked, isTrue);
    });

    testWidgets('unlock() resets isLocked and notifies listeners',
        (WidgetTester tester) async {
      final service = SessionTimeoutService();
      service.lock();
      expect(service.isLocked, isTrue);

      var notified = false;
      service.addListener(() => notified = true);

      service.unlock();
      expect(service.isLocked, isFalse);
      expect(notified, isTrue);
    });

    testWidgets('timer triggers timeout callback', (WidgetTester tester) async {
      final service = SessionTimeoutService();
      service.setTimeoutDuration(const Duration(milliseconds: 100));

      bool timedOut = false;
      service.setOnTimeoutCallback(() => timedOut = true);

      service.start();

      // Wait for the short timeout
      await tester.pump(const Duration(milliseconds: 200));

      expect(timedOut, isTrue);
      expect(service.isLocked, isTrue);
    });

    testWidgets('resetTimer cancels pending timeout',
        (WidgetTester tester) async {
      final service = SessionTimeoutService();
      service.setTimeoutDuration(const Duration(milliseconds: 500));

      bool timedOut = false;
      service.setOnTimeoutCallback(() => timedOut = true);

      service.start();
      await tester.pump(const Duration(milliseconds: 300));

      service.resetTimer();
      await tester.pump(const Duration(milliseconds: 300));

      expect(timedOut, isFalse);

      await tester.pump(const Duration(milliseconds: 300));
      expect(timedOut, isTrue);
    });
  });
}
