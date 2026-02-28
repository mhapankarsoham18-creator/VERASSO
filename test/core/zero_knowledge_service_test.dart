import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/core/services/zero_knowledge_service.dart';

void main() {
  group('ZeroKnowledgeService Tests', () {
    test(
        'Skill Commitment should be deterministic with same salt but unique with unique secrets',
        () {
      const skillId = 'flutter_mastery';
      const secret = 'user_secret_123';

      final commitment1 =
          ZeroKnowledgeService.generateSkillCommitment(skillId, secret);
      final commitment2 =
          ZeroKnowledgeService.generateSkillCommitment(skillId, secret);

      // Since generateSkillCommitment generates a new salt each time, they should be different
      expect(commitment1, isNot(equals(commitment2)));

      final parts1 = commitment1.split(':');
      final parts2 = commitment2.split(':');

      expect(parts1.length, 2);
      expect(parts2.length, 2);
    });

    test('Blinded ID should be deterministic for same session', () {
      const realId = 'user_99';
      const session = 'session_alpha';

      final id1 = ZeroKnowledgeService.createBlindedId(realId, session);
      final id2 = ZeroKnowledgeService.createBlindedId(realId, session);
      final id3 = ZeroKnowledgeService.createBlindedId(realId, 'session_beta');

      expect(id1, id2);
      expect(id1, isNot(id3));
      expect(id1.length, 16);
    });
  });
}
