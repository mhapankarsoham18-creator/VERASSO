// Basic Flutter widget smoke test for Verasso.
//
// This test verifies the VerassoApp widget can be instantiated and
// builds a MaterialApp. Full route/auth tests require Firebase mocking.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verasso/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build the app widget. The GoRouter redirect uses FirebaseAuth which
    // is not initialized in unit tests, so we expect an error widget.
    // The smoke test validates that VerassoApp itself constructs OK.
    await tester.pumpWidget(const ProviderScope(child: VerassoApp()));

    // Allow one frame to render (pumpAndSettle may hang on error state)
    await tester.pump();

    // Verify the MaterialApp was created (proves VerassoApp built successfully)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
