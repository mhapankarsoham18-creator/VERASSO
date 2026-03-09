// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in the test, use the WidgetTester
// utility in the flutter_test package.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Basic widget test passes', (WidgetTester tester) async {
    // Build a simple widget
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Test'))),
    );

    // Verify the widget is found
    expect(find.text('Test'), findsOneWidget);
  });
}
