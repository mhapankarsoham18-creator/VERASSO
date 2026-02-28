import 'package:codemaster_odyssey/src/features/editor/presentation/odyssey_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('OdysseyEditor renders and updates code', (tester) async {
    String code = 'print("init")';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OdysseyEditor(
            initialCode: code,
            onChanged: (value) => code = value,
          ),
        ),
      ),
    );

    // Verify initial render
    expect(find.text('print("init")'), findsOneWidget);
    expect(find.text('1'), findsOneWidget); // Line number

    // Enter text
    await tester.enterText(find.byType(TextField), 'new code');
    expect(code, 'new code');
  });
}
