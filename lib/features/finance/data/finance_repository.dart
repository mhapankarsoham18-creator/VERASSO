import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/monitoring/sentry_service.dart';
import 'package:verasso/features/finance/data/transaction_model.dart';
import 'package:verasso/features/finance/models/accounting_model.dart';

import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/services/supabase_service.dart';

/// Provides access to the `FinanceRepository` for dependency injection.
final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  return FinanceRepository();
});

/// Repository responsible for managing financial data.
class FinanceRepository {
  final SupabaseClient _client;

  /// Creates a [FinanceRepository] with an optional [SupabaseClient].
  FinanceRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  /// Persists a new [JournalEntry].
  Future<void> addEntry(JournalEntry entry) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final journalResponse = await _client
        .from('finance_journal_entries')
        .insert({
          'user_id': userId,
          'description': entry.description,
          'date': entry.date.toIso8601String(),
        })
        .select()
        .single();

    final journalId = journalResponse['id'];

    final linesData = entry.lines
        .map((l) => {
              'journal_entry_id': journalId,
              'account_name': l.accountName,
              'amount': l.amount,
              'transaction_type':
                  l.type == TransactionType.debit ? 'debit' : 'credit',
            })
        .toList();

    await _client.from('finance_transaction_lines').insert(linesData);
  }

  /// Records a single portfolio transaction.
  Future<void> addPortfolioTransaction(
    String symbol,
    String type,
    double units,
    double price,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('portfolio_transactions').insert({
      'user_id': userId,
      'symbol': symbol,
      'type': type,
      'units': units,
      'price': price,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Creates a recurring transaction.
  Future<void> createRecurringTransaction({
    required String userId,
    required double amount,
    required String frequency,
    String? description,
  }) async {
    await _client.from('recurring_transactions').insert({
      'user_id': userId,
      'amount': amount,
      'frequency': frequency,
      'description': description,
    });
  }

  /// Alias for [recordTransaction].
  Future<void> createTransaction({
    required String userId,
    required String type,
    required double amount,
    required String category,
    String? description,
    String currency = 'USD',
  }) =>
      recordTransaction(
        userId: userId,
        type: type,
        amount: amount,
        category: category,
        description: description,
        currency: currency,
      );

  /// Deletes a transaction.
  Future<void> deleteTransaction(String transactionId) async {
    await _client.from('transactions').delete().eq('id', transactionId);
  }

  /// Fetches a financial account summary.
  Future<FinancialAccount> getAccount(String userId) async {
    final response = await _client
        .from('financial_accounts')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      return FinancialAccount(
        userId: userId,
        balance: 0.0,
        updatedAt: DateTime.now(),
      );
    }
    return FinancialAccount.fromJson(response);
  }

  /// Fetches budget details.
  Future<Budget> getBudget(String userId, [String? category]) async {
    final query = _client.from('budgets').select().eq('user_id', userId);
    if (category != null) query.eq('category', category);

    final response = await query.maybeSingle();
    if (response == null) {
      return Budget(
          userId: userId, category: category ?? 'all', limit: 0.0, spent: 0.0);
    }
    return Budget.fromJson(response);
  }

  /// Fetches business state.
  Future<Map<String, dynamic>?> getBusinessState() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('business_states')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    return response;
  }

  /// Fetches financial stats.
  Future<Map<String, double>> getFinancialStats(String userId) async {
    final transactions = await getTransactionHistory(userId);
    double income = 0.0;
    double expense = 0.0;
    for (var tx in transactions) {
      if (tx.isCredit) {
        income += tx.amount;
      } else {
        expense += tx.amount;
      }
    }
    return {'income': income, 'expense': expense};
  }

  /// Fetches income breakdown.
  Future<Map<String, double>> getIncomeBreakdown(String userId) async {
    try {
      final transactions = await getTransactionHistory(userId);
      final Map<String, double> breakdown = {};

      for (var tx in transactions) {
        if (tx.isCredit) {
          final category = tx.category.isEmpty ? 'Other' : tx.category;
          breakdown[category] = (breakdown[category] ?? 0) + tx.amount;
        }
      }
      return breakdown;
    } catch (e, stack) {
      AppLogger.warning('Failed to calculate income breakdown', error: e);
      SentryService.captureException(e, stackTrace: stack);
      return {};
    }
  }

  /// Fetches journal.
  Future<List<JournalEntry>> getJournal() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('finance_journal_entries')
        .select('*, finance_transaction_lines(*)')
        .eq('user_id', userId)
        .order('date', ascending: false);

    return (response as List).map((json) {
      final linesJson = json['finance_transaction_lines'] as List;
      return JournalEntry(
        id: json['id'],
        description: json['description'],
        date: DateTime.parse(json['date']),
        lines: linesJson
            .map((l) => TransactionLine(
                  accountName: l['account_name'],
                  amount: (l['amount'] as num).toDouble(),
                  type: l['transaction_type'] == 'debit'
                      ? TransactionType.debit
                      : TransactionType.credit,
                ))
            .toList(),
      );
    }).toList();
  }

  /// Fetches ledgers.
  Future<Map<String, LedgerAccount>> getLedgers() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return {};

    final response =
        await _client.from('finance_ledgers').select().eq('user_id', userId);

    final Map<String, LedgerAccount> ledgers = {};
    for (var row in (response as List)) {
      final name = row['account_name'];
      ledgers[name] = LedgerAccount(
        name: name,
        transactions: [],
      );
    }
    return ledgers;
  }

  /// Fetches monthly earnings.
  Future<Map<String, double>> getMonthlyEarnings(String userId) async {
    try {
      final response = await _client.rpc('get_monthly_finance_stats', params: {
        'p_user_id': userId,
        'p_months': 6,
      });

      final Map<String, double> monthlyData = {};
      for (var row in (response as List)) {
        monthlyData[row['month_name']] =
            (row['total_amount'] as num).toDouble();
      }
      return monthlyData;
    } catch (e, stack) {
      AppLogger.warning('Failed monthly stats RPC, falling back', error: e);
      SentryService.captureException(e, stackTrace: stack);

      final transactions = await getTransactionHistory(userId);
      final Map<String, double> monthlyData = {};

      final now = DateTime.now();
      for (int i = 5; i >= 0; i--) {
        final date = DateTime(now.year, now.month - i, 1);
        final key = DateFormat('MMM').format(date);
        monthlyData[key] = 0.0;
      }

      for (var tx in transactions) {
        if (tx.isCredit) {
          final key = DateFormat('MMM').format(tx.createdAt);
          if (monthlyData.containsKey(key)) {
            monthlyData[key] = (monthlyData[key] ?? 0) + tx.amount;
          }
        }
      }
      return monthlyData;
    }
  }

  /// Calculates net worth.
  Future<double> getNetWorth(String userId) async {
    final transactions = await getTransactionHistory(userId);
    double total = 0.0;
    for (var tx in transactions) {
      if (tx.isCredit) {
        total += tx.amount;
      } else {
        total -= tx.amount;
      }
    }
    return total;
  }

  /// Fetches portfolio holdings.
  Future<List<Map<String, dynamic>>> getPortfolioHoldings() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response =
        await _client.from('portfolio_holdings').select().eq('user_id', userId);
    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Fetches portfolio meta.
  Future<Map<String, dynamic>> getPortfolioMeta() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return {};

    final response = await _client
        .from('portfolio_meta')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    return response ?? {};
  }

  /// Fetches portfolio transactions.
  Future<List<Map<String, dynamic>>> getPortfolioTransactions() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('portfolio_transactions')
        .select()
        .eq('user_id', userId);
    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Fetches transaction history.
  Future<List<Transaction>> getTransactionHistory(String userId) async {
    final response = await _client
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Transaction.fromJson(json))
        .toList();
  }

  /// Fetches transaction history.
  Future<List<Transaction>> getTransactions(String userId) =>
      getTransactionHistory(userId);

  /// Fetches transactions by category.
  Future<List<Transaction>> getTransactionsByCategory({
    required String userId,
    required String category,
  }) async {
    final response = await _client
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .eq('category', category)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Transaction.fromJson(json))
        .toList();
  }

  /// Fetches transactions within a date range.
  Future<List<Transaction>> getTransactionsByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await _client
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .gte('created_at', startDate.toIso8601String())
        .lte('created_at', endDate.toIso8601String())
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Transaction.fromJson(json))
        .toList();
  }

  /// Records a new transaction.
  Future<void> recordTransaction({
    required String userId,
    required String type,
    required double amount,
    required String category,
    String? description,
    String currency = 'USD',
  }) async {
    await _client.from('transactions').insert({
      'user_id': userId,
      'type': type,
      'amount': amount,
      'category': category,
      'description': description,
      'currency': currency,
    });
  }

  /// Saves business state.
  Future<void> saveBusinessState(Map<String, dynamic> data) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('business_states').upsert({
      'user_id': userId,
      ...data,
    });
  }

  /// Updates portfolio meta.
  Future<void> updatePortfolioMeta(double cashBalance, int totalXP) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('portfolio_meta').upsert({
      'user_id': userId,
      'cash_balance': cashBalance,
      'total_xp_earned': totalXP,
    });
  }

  /// Updates a transaction.
  Future<void> updateTransaction({
    required String transactionId,
    double? amount,
    String? category,
    String? type,
    String? description,
  }) async {
    final Map<String, dynamic> updates = {};
    if (amount != null) updates['amount'] = amount;
    if (category != null) updates['category'] = category;
    if (type != null) updates['type'] = type;
    if (description != null) updates['description'] = description;

    if (updates.isNotEmpty) {
      await _client
          .from('transactions')
          .update(updates)
          .eq('id', transactionId);
    }
  }

  /// Uploads a receipt image and associates it with a transaction.
  Future<String> uploadReceipt(String transactionId, String filePath) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not logged in');

    final file = File(filePath);
    if (!await file.exists()) throw Exception('File not found at $filePath');

    try {
      final fileName =
          'receipts/${DateTime.now().millisecondsSinceEpoch}_$transactionId.jpg';
      await _client.storage.from('finance').upload(fileName, file);
      final url = _client.storage.from('finance').getPublicUrl(fileName);

      await _client.from('transactions').update({
        'receipt_url': url,
      }).eq('id', transactionId);

      return url;
    } catch (e) {
      AppLogger.error('Upload receipt error', error: e);
      throw DatabaseException('Failed to upload receipt', null, e);
    }
  }

  /// Upserts portfolio holding.
  Future<void> upsertPortfolioHolding(
    String symbol,
    String name,
    double units,
    double avgPrice,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('portfolio_holdings').upsert({
      'user_id': userId,
      'symbol': symbol,
      'name': name,
      'units': units,
      'avg_price': avgPrice,
    });
  }
}
