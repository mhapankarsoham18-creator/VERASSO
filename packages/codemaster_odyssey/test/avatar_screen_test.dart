import 'package:codemaster_odyssey/src/features/avatar/presentation/avatar_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AvatarScreen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AvatarScreen())),
    );

    // Verify TabBar
    expect(find.text('PROFILE'), findsOneWidget);
    expect(find.text('SKILL TREE'), findsOneWidget);

    // Verify Profile Tab content (default)
    expect(find.text('AVATAR SYSTEM'), findsOneWidget);
    expect(
      find.text('CODE APPRENTICE'),
      findsOneWidget,
    ); // Default name uppercase
    expect(find.text('LOGIC'), findsOneWidget);

    // Switch to Skill Tree Tab
    await tester.tap(find.text('SKILL TREE'));
    await tester.pumpAndSettle();

    // Verify Skill Tree content
    expect(find.text('Basic Logic'), findsOneWidget);
    expect(find.text('Unlock if/else statements.'), findsOneWidget);
  });
}
