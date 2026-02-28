import 'package:flutter_test/flutter_test.dart';
import 'package:pinenacl/ed25519.dart' as pinenacl;
import 'package:verasso/core/services/mastery_signature_service.dart';

void main() {
  late MasterySignatureService service;
  late pinenacl.SigningKey signingKey;

  setUp(() {
    service = MasterySignatureService();
    signingKey = pinenacl.SigningKey.generate();
  });

  group('MasterySignatureService Tests', () {
    test('generates a valid signed transcript', () {
      final skills = {'Flutter': 0.9, 'Dart': 0.8};
      final userId = 'test-user-123';

      final transcript = service.generateSignedTranscript(
        userId: userId,
        skills: skills,
        signingKey: signingKey,
      );

      expect(transcript, isNotNull);
      expect(transcript, contains('test-user-123'));
      expect(transcript, contains('skl'));
      expect(transcript, contains('sig'));
    });

    test('verifies a valid transcript successfully', () {
      final skills = {'Security': 0.7};
      final userId = 'secure-user';

      final transcript = service.generateSignedTranscript(
        userId: userId,
        skills: skills,
        signingKey: signingKey,
      );

      final isValid = service.verifyTranscript(transcript);
      expect(isValid, isTrue);
    });

    test('fails verification for tampered transcript', () {
      final skills = {'Math': 1.0};
      final userId = 'student-1';

      final transcript = service.generateSignedTranscript(
        userId: userId,
        skills: skills,
        signingKey: signingKey,
      );

      // Tamper with the payload (e.g., change uid)
      final tampered = transcript.replaceAll('student-1', 'attacker');

      final isValid = service.verifyTranscript(tampered);
      expect(isValid, isFalse);
    });

    test('handles invalid JSON gracefully', () {
      final isValid = service.verifyTranscript('invalid-json');
      expect(isValid, isFalse);
    });
  });
}
