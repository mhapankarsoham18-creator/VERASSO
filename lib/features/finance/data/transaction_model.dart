/// Represents a general finance transaction associated with a user.
class Transaction {
  /// Unique identifier for the transaction.
  final String id;

  /// Unique identifier of the user who performed the transaction.
  final String userId;

  /// The type of transaction (e.g., 'Credit', 'Debit').
  final String type;

  /// The monetary amount of the transaction.
  final double amount;

  /// The currency code (e.g., 'USD').
  final String currency;

  /// The category of the transaction (e.g., 'Mentorship', 'Job').
  final String category;

  /// An optional user-provided description of the transaction.
  final String? description;

  /// The timestamp of when the transaction was recorded.
  final DateTime createdAt;

  /// Creates a [Transaction].
  Transaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    this.currency = 'USD',
    required this.category,
    this.description,
    required this.createdAt,
  });

  /// Creates a [Transaction] from a JSON-compatible map.
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      userId: json['user_id'],
      type: json['type'],
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] ?? 'USD',
      category: json['category'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  /// Returns true if this transaction is a credit (positive inflow).
  bool get isCredit => type == 'Credit' || type == 'credit';
}
