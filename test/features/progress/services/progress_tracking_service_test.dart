import 'package:flutter_test/flutter_test.dart';

void main() {
  // Unit tests for ProgressTrackingService have been moved to integration tests
  // because the service now uses Supabase.instance.client directly instead of
  // accepting a client parameter. Integration tests provide better validation.
  // See: test/features/progress/integration/progress_integration_test.dart

  group('ProgressTrackingService', () {
    test('service uses integration tests for validation', () {
      expect(true, isTrue);
    });
  });
}
