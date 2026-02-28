import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/astronomy/presentation/astronomy_menu_screen.dart';
import 'package:verasso/features/settings/presentation/theme_controller.dart';

import '../../mocks.dart';

void main() {
  testWidgets('AstronomyMenuScreen renders correctly', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themeControllerProvider.overrideWith((ref) => MockThemeController()),
        ],
        child: const MaterialApp(home: AstronomyMenuScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Verify title
    expect(find.text('Cosmic Explorer'), findsOneWidget);

    // Verify menu items
    expect(find.text('AR Stargazing'), findsOneWidget);
    expect(find.text('Stargazing Logs'), findsOneWidget);
    expect(find.text('Solar System 3D'), findsOneWidget);

    // Verify mission parameters
    expect(find.text('Mission Parameters'), findsOneWidget);
    expect(find.text('Precision GPS Lock'), findsOneWidget);
  });
}
