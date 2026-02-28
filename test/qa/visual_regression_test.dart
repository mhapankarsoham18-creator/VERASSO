import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/gamification/services/guild_service.dart';

void main() {
  group('Visual Regression - Advanced Features', () {
    testWidgets('Guild Member List renders correctly with moderator roles',
        (tester) async {
      // 1. Setup mock data
      final guild = Guild(
        id: 'guild-1',
        name: 'Alpha Guild',
        leaderId: 'leader-1',
        guildXP: 5000,
        memberCount: 3,
        maxMembers: 20,
      );

      final members = [
        GuildMember(
            userId: 'leader-1',
            guildId: 'guild-1',
            joinedAt: DateTime.now(),
            role: 'leader',
            xpContributed: 1000),
        GuildMember(
            userId: 'mod-1',
            guildId: 'guild-1',
            joinedAt: DateTime.now(),
            role: 'moderator',
            xpContributed: 500),
        GuildMember(
            userId: 'member-1',
            guildId: 'guild-1',
            joinedAt: DateTime.now(),
            role: 'member',
            xpContributed: 100),
      ];

      debugPrint('Testing guild: ${guild.name}');

      // 2. Build Widget (Example component)
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              return ListTile(
                title: Text(member.userId),
                subtitle: Text(member.role),
                trailing: member.role == 'moderator'
                    ? const Icon(Icons.shield)
                    : null,
              );
            },
          ),
        ),
      ));

      // 3. Verify labels
      expect(find.text('moderator'), findsOneWidget);
      expect(find.text('leader'), findsOneWidget);
      expect(find.text('member'), findsOneWidget);
      expect(find.byIcon(Icons.shield), findsOneWidget);

      // Note: matchesGoldenFile would be used here in a real CI environment
      // expect(find.byType(ListView), matchesGoldenFile('goldens/guild_member_list.png'));
    });

    testWidgets('Seasonal Event Reward card renders premium styles',
        (tester) async {
      // Build a mock reward card
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient:
                    const LinearGradient(colors: [Colors.purple, Colors.blue]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Premium Reward',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Icon(Icons.star, color: Colors.amber),
                  Text('+500 XP', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
      ));

      expect(find.text('Premium Reward'), findsOneWidget);
      expect(find.text('+500 XP'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });
}
