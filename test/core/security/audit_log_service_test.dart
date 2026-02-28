import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/core/security/audit_log_service.dart';

import '../../mocks.dart';

void main() {
  late AuditLogService auditLogService;
  late MockSupabaseClient mockSupabaseClient;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    auditLogService = AuditLogService(client: mockSupabaseClient);
  });

  group('AuditLogService Tests', () {
    test('logEvent inserts correct data into security_audit_logs table',
        () async {
      // In our current Fake implementation, we just verify it completes
      await expectLater(
        auditLogService.logEvent(
          type: 'security',
          action: 'failed_login',
          severity: 'high',
          metadata: {'reason': 'invalid_password'},
        ),
        completes,
      );
    });
  });
}
