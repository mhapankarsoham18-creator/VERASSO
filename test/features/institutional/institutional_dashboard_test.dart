import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/institutional/presentation/institutional_dashboard.dart';
import 'package:verasso/features/settings/presentation/theme_controller.dart';

void main() {
  testWidgets('InstitutionalDashboard renders correctly', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themeControllerProvider.overrideWith((ref) => ThemeController()
            ..state = AppThemeState(
              mode: ThemeMode.system,
              primaryColor: Colors.blue,
              accentColor: Colors.blueAccent,
              isPowerSaveMode: true,
            )),
        ],
        child: const MaterialApp(home: InstitutionalDashboard()),
      ),
    );

    // Verify title
    expect(find.text('Institutional Mastery'), findsOneWidget);

    // Verify stats
    expect(find.text('Local Network Analytics'), findsOneWidget);
    expect(find.text('Active Peers'), findsOneWidget);
    expect(find.text('Avg Mastery'), findsOneWidget);
    expect(find.text('78%'), findsOneWidget);

    // Verify peer list
    expect(find.text('Peer Proficiency Breakout'), findsOneWidget);
    expect(find.text('User_442'), findsOneWidget);
    expect(find.text('Pharmacology'), findsOneWidget);
  });
}
