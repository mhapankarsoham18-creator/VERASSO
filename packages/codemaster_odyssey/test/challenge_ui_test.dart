import 'package:codemaster_odyssey/src/features/challenge/presentation/challenge_list_screen.dart';
import 'package:codemaster_odyssey/src/features/challenge/presentation/challenge_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ChallengeListScreen renders challenges', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ChallengeListScreen())),
    );

    expect(find.text('CHALLENGE LIBRARY'), findsOneWidget);
    expect(find.text('The Loop of Infinity'), findsOneWidget);
    expect(find.text('EASY'), findsOneWidget);

    // Settle animations
    await tester.pumpAndSettle();
  });

  testWidgets('ChallengeScreen allows code submission', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ChallengeScreen(challengeId: 'c1')),
      ),
    );

    expect(find.text('The Loop of Infinity'), findsOneWidget);
    expect(find.text('SUBMIT SOLUTION'), findsOneWidget);

    // Initial state
    expect(find.text('Challenge Solved!'), findsNothing);

    // Enter some code (must contain "print")
    await tester.enterText(find.byType(TextField), 'print("Echo")');
    await tester.tap(find.text('SUBMIT SOLUTION'));
    await tester.pumpAndSettle();

    expect(find.text('Challenge Solved! Reward Claimed.'), findsOneWidget);
  });
}
