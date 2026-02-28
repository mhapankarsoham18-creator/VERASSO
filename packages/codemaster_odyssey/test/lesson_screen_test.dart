import 'package:codemaster_odyssey/src/features/lesson/presentation/lesson_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('LessonScreen renders correctly and validates code', (
    WidgetTester tester,
  ) async {
    // Build the widget
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LessonScreen(realmId: '1', lessonId: 'p1_l1'),
        ),
      ),
    );

    // Verify title and content
    expect(find.text('The Print Spell'), findsOneWidget);
    // Markdown renders differently, so we look for the text within the markdown body
    expect(find.text('The Power of Print', findRichText: true), findsOneWidget);

    // Verify Run button exists
    expect(find.text('RUN CODE'), findsOneWidget);

    // Initial state: No feedback
    expect(find.text('SUCCESS!'), findsNothing);

    // Tap Run Code (with default incorrect starter code)
    await tester.tap(find.text('RUN CODE'));
    await tester.pump();

    // Verify Error feedback
    expect(find.textContaining('Oops!'), findsOneWidget);

    // Enter correct code
    await tester.enterText(find.byType(TextField), 'print("I am a Coder")');
    await tester.tap(find.text('RUN CODE'));
    await tester.pump();

    // Verify Success feedback
    expect(find.textContaining('SUCCESS!'), findsOneWidget);

    // Wait for any animations (BadgeNotification) to settle or timers to finish
    await tester.pumpAndSettle();
  });

  testWidgets('LessonScreen shows AI Tutor on request', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LessonScreen(realmId: '1', lessonId: 'p1_l1'),
        ),
      ),
    );

    // Verify AI Tutor button exists (psychology icon)
    expect(find.byIcon(Icons.psychology), findsOneWidget);

    // Tap AI Tutor button
    await tester.tap(find.byIcon(Icons.psychology));
    // Validating animation presence, so just pump a few frames
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify AI Tutor widget appears
    expect(find.text('AI TUTOR'), findsOneWidget);
    expect(
      find.text('I am ready to analyze your code, Apprentice.'),
      findsOneWidget,
    );

    // Verify Analyze button exists
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });
}
