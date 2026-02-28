import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/services/supabase_service.dart';

/// Provider for the [TransactionRepository] instance.
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

/// Represents a financial or point-based transaction within the learning module.
class Transaction {
  /// Unique identifier of the transaction.
  final String id;

  /// The ID of the user involved in the transaction.
  final String userId;

  /// Optional target ID (e.g., Course ID, Item ID) related to the transaction.
  final String? targetId;

  /// The type of the transaction (e.g., purchase, reward).
  final TransactionType type;

  /// The amount involved in the transaction.
  final double amount;

  /// The currency code (defaults to 'VER' for internal credits).
  final String currency;

  /// The date and time when the transaction occurred.
  final DateTime createdAt;

  /// Additional metadata associated with the transaction.
  final Map<String, dynamic> metadata;

  /// Creates a [Transaction] instance.
  Transaction({
    required this.id,
    required this.userId,
    this.targetId,
    required this.type,
    required this.amount,
    this.currency = 'VER',
    required this.createdAt,
    this.metadata = const {},
  });

  /// Creates a [Transaction] from a JSON-compatible map.
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      userId: json['user_id'],
      targetId: json['target_id'],
      type: TransactionType.values.firstWhere((e) => e.name == json['type']),
      amount: (json['amount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'VER',
      createdAt: DateTime.parse(json['created_at']),
      metadata: json['metadata'] ?? {},
    );
  }

  /// Converts the [Transaction] instance to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'target_id': targetId,
      'type': type.name,
      'amount': amount,
      'currency': currency,
      'metadata': metadata,
    };
  }
}

/// Repository for managing transaction history and user balance.
class TransactionRepository {
  final SupabaseClient _client;

  /// Creates a [TransactionRepository] instance.
  TransactionRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  /// Retrieves the transaction history for a specific user.
  Future<List<Transaction>> getTransactionHistory(String userId) async {
    try {
      final response = await _client
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((e) => Transaction.fromJson(e)).toList();
    } catch (e) {
      AppLogger.error('TransactionRepository: History error', error: e);
      return [];
    }
  }

  /// Retrieves the current balance of a specific user.
  Future<double> getUserBalance(String userId) async {
    try {
      final response =
          await _client.rpc('get_user_balance', params: {'user_id': userId});
      return (response ?? 0.0).toDouble();
    } catch (e) {
      AppLogger.error('TransactionRepository: Balance error', error: e);
      return 0.0;
    }
  }

  /// Records a new transaction in the database.
  Future<void> recordTransaction(Transaction transaction) async {
    try {
      await _client.from('transactions').insert(transaction.toJson());
    } catch (e) {
      AppLogger.error('TransactionRepository: Record error', error: e);
      throw Exception('Failed to record transaction: $e');
    }
  }
}

/// Defines the various types of transactions available in the system.
enum TransactionType {
  /// Credits added to the account.
  deposit,

  /// Credits removed/withdrawn from the account.
  withdrawal,

  /// Credits used to buy courses or items.
  purchase,

  /// Credits earned as a reward for activity.
  reward,

  /// Credits returned after a transaction reversal.
  refund
}
