import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/finance/data/finance_repository.dart';

import '../../mocks.dart';

void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late FinanceRepository repository;

  setUp(() {
    mockAuth = MockGoTrueClient();
    mockSupabase = MockSupabaseClient(auth: mockAuth);
    repository = FinanceRepository(client: mockSupabase);
  });

  group('FinanceRepository', () {
    const userId = 'test-user-id';

    test('getFinancialStats calculates income and expense correctly', () async {
      // Arrange
      final transactionsJson = [
        {
          'id': '1',
          'user_id': userId,
          'type': 'Credit', // Matches isCredit getter
          'amount': 1000.0,
          'category': 'Salary',
          'description': 'Monthly Salary',
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'id': '2',
          'user_id': userId,
          'type': 'Debit', // Not Credit
          'amount': 200.0,
          'category': 'Food',
          'description': 'Groceries',
          'created_at': DateTime.now().toIso8601String(),
        },
      ];

      final mockQueryBuilder =
          MockSupabaseQueryBuilder(selectResponse: transactionsJson);
      mockSupabase.setQueryBuilder('transactions', mockQueryBuilder);

      // Act
      final stats = await repository.getFinancialStats(userId);

      // Assert
      expect(stats['income'], 1000.0);
      expect(stats['expense'], 200.0);
    });

    test('getNetWorth calculates correct net worth', () async {
      // Arrange
      final transactionsJson = [
        {
          'id': '1',
          'user_id': userId,
          'type': 'Credit',
          'amount': 500.0,
          'category': 'Gig',
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'id': '2',
          'user_id': userId,
          'type': 'Debit',
          'amount': 100.0,
          'category': 'Rent',
          'created_at': DateTime.now().toIso8601String(),
        },
      ];

      final mockQueryBuilder =
          MockSupabaseQueryBuilder(selectResponse: transactionsJson);
      mockSupabase.setQueryBuilder('transactions', mockQueryBuilder);

      // Act
      final netWorth = await repository.getNetWorth(userId);

      // Assert
      expect(netWorth, 400.0);
    });
  });
}
