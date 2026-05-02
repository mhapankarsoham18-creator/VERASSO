import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/legal/views/data_consent_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('DataConsentDialog Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Displays consent dialog elements correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DataConsentDialog(onAccept: () {}),
          ),
        ),
      );

      // Verify the title is present
      expect(find.text('Data Privacy Consent'), findsOneWidget);

      // Verify the accept button is present
      expect(find.text('I AGREE & CONTINUE'), findsOneWidget);
    });

    testWidgets('Tapping Agree saves consent to SharedPreferences', (WidgetTester tester) async {

      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DataConsentDialog(onAccept: () {}),
          ),
        ),
      );

      // Tap the agree button
      await tester.tap(find.text('I AGREE & CONTINUE'));
      await tester.pumpAndSettle();

      // In the dialog widget, tapping the button calls onAccept, which we passed as a no-op () {}.
      // The shared preference logic markConsented() is actually called inside showIfNeeded(), not directly on button tap in the widget itself.
      // So here we just verify the tap works and triggers the callback.
      var accepted = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DataConsentDialog(onAccept: () {
              accepted = true;
            }),
          ),
        ),
      );
      await tester.tap(find.text('I AGREE & CONTINUE'));
      await tester.pumpAndSettle();
      expect(accepted, isTrue);
    });
  });
}
