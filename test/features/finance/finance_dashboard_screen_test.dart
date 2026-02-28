import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/auth/domain/auth_service.dart';
import 'package:verasso/features/auth/presentation/auth_controller.dart';
import 'package:verasso/features/finance/data/finance_repository.dart';
import 'package:verasso/features/finance/data/transaction_model.dart';
import 'package:verasso/features/finance/presentation/finance_dashboard_screen.dart';
import 'package:verasso/features/settings/presentation/theme_controller.dart';

import '../../mocks.dart';

void main() {
  late MockFinanceRepository mockFinanceRepository;
  late DomainAuthUser mockUser;

  setUp(() {
    mockFinanceRepository = MockFinanceRepository();
    // Use a simpler mock for user if possible, or just the MockUser class
    mockUser = DomainAuthUser(id: 'test-user-id', email: 'test@example.com');
  });

  Widget createSubject({DomainAuthUser? currentUser}) {
    return ProviderScope(
      overrides: [
        financeRepositoryProvider.overrideWithValue(mockFinanceRepository),
        currentUserProvider.overrideWith((ref) => currentUser),
        themeControllerProvider.overrideWith((ref) => MockThemeController()),
      ],
      child: const MaterialApp(
        home: FinanceDashboardScreen(),
      ),
    );
  }

  group('FinanceDashboardScreen', () {
    testWidgets('renders "Please log in" when unauthenticated',
        (WidgetTester tester) async {
      await tester.pumpWidget(createSubject(currentUser: null));
      expect(find.text('Please log in'), findsOneWidget);
    });

    testWidgets('renders dashboard when authenticated',
        (WidgetTester tester) async {
      // Stubing repository methods
      mockFinanceRepository.stubGetFinancialStats = (String userId) async {
        return {'income': 5000.0, 'expense': 2000.0};
      };
      mockFinanceRepository.stubGetTransactionHistory = (String userId) async {
        return [];
      };

      await tester.pumpWidget(createSubject(currentUser: mockUser));
      await tester.pumpAndSettle();

      expect(find.text('Financial Hub'), findsOneWidget);
      expect(find.text('Total Net Earnings'), findsOneWidget);
      // Net worth = 5000 - 2000 = 3000
      expect(find.text('\$3000.00'), findsOneWidget);
    });

    testWidgets('shows simple transaction history',
        (WidgetTester tester) async {
      mockFinanceRepository.stubGetFinancialStats = (userId) async => {};
      mockFinanceRepository.stubGetTransactionHistory = (userId) async {
        return [
          Transaction(
            id: 't1',
            userId: userId,
            amount: 100.0,
            type: 'Credit',
            category: 'Salary',
            description: 'Test Salary',
            createdAt: DateTime(2023, 1, 1),
          ),
        ];
      };

      await tester.pumpWidget(createSubject(currentUser: mockUser));
      await tester.pumpAndSettle();

      expect(find.text('Test Salary'), findsOneWidget);
      expect(find.text('+ \$100.00'), findsOneWidget);
    });
  });
}

// Helper mock for simple usage in this test file
class MockFinanceRepository extends Fake implements FinanceRepository {
  Future<Map<String, double>> Function(String)? stubGetFinancialStats;
  Future<List<Transaction>> Function(String)? stubGetTransactionHistory;

  @override
  Future<Map<String, double>> getFinancialStats(String userId) async {
    if (stubGetFinancialStats != null) {
      return stubGetFinancialStats!(userId);
    }
    return {'income': 0.0, 'expense': 0.0};
  }

  @override
  Future<List<Transaction>> getTransactionHistory(String userId) async {
    if (stubGetTransactionHistory != null) {
      return stubGetTransactionHistory!(userId);
    }
    return [];
  }
}
