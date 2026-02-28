import 'package:codemaster_odyssey/src/features/lesson/presentation/lesson_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('LessonScreen debugger steps through code', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LessonScreen(realmId: '1', lessonId: 'l1'),
        ),
      ),
    );

    // Initial state: No debugger
    expect(find.text('DEBUG'), findsOneWidget);
    expect(find.text('STEP'), findsNothing);

    // Enter some loop code to trigger simulated debugger steps
    await tester.enterText(
      find.byType(TextField),
      'for i in range(3):\n  print(i)',
    );

    // Start Debug
    await tester.tap(find.text('DEBUG'));
    await tester.pumpAndSettle();

    expect(find.text('STEP'), findsOneWidget);
    expect(find.text('DEBUGGING: Step through the execution.'), findsOneWidget);

    // Step 1
    await tester.tap(find.text('STEP'));
    await tester.pumpAndSettle();

    // Verify variable display (Scroll of Truth)
    expect(find.text('VARIABLES'), findsOneWidget);
    expect(find.text('i'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    // Step more
    await tester.tap(find.text('STEP'));
    await tester.pumpAndSettle();

    // Next step change variable
    await tester.tap(find.text('STEP'));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
  });
}
