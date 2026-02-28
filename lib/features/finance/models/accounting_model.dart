/// Represents a budget for a specific category.
class Budget {
  /// The ID of the user who owns this budget.
  final String userId;

  /// The budget category (e.g., 'Groceries', 'Rent').
  final String category;

  /// The maximum amount allocated for this category.
  final double limit;

  /// The amount already spent in this category.
  final double spent;

  /// Creates a [Budget].
  Budget({
    required this.userId,
    required this.category,
    required this.limit,
    required this.spent,
  });

  /// Creates a [Budget] from a JSON map.
  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      userId: json['user_id'] ?? '',
      category: json['category'] ?? '',
      limit: (json['limit'] as num?)?.toDouble() ?? 0.0,
      spent: (json['spent'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Represents a financial account summary.
class FinancialAccount {
  /// The ID of the user who owns this account.
  final String userId;

  /// The current balance of the account.
  final double balance;

  /// The currency code (e.g., 'USD', 'EUR').
  final String currency;

  /// The date and time when the account details were last updated.
  final DateTime updatedAt;

  /// The total amount of debits across all transactions.
  final double totalDebits;

  /// The total amount of credits across all transactions.
  final double totalCredits;

  /// Creates a [FinancialAccount].
  FinancialAccount({
    required this.userId,
    required this.balance,
    this.currency = 'USD',
    required this.updatedAt,
    this.totalDebits = 0.0,
    this.totalCredits = 0.0,
  });

  /// Creates a [FinancialAccount] from a JSON map.
  factory FinancialAccount.fromJson(Map<String, dynamic> json) {
    return FinancialAccount(
      userId: json['user_id'] ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'USD',
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      totalDebits: (json['total_debits'] as num?)?.toDouble() ?? 0.0,
      totalCredits: (json['total_credits'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Represents a double-entry bookkeeping journal entry.
class JournalEntry {
  /// Unique identifier for the journal entry.
  final String id;

  /// A brief description of the transaction.
  final String description;

  /// The date the entry was recorded.
  final DateTime date;

  /// The list of credit and debit lines associated with this entry.
  final List<TransactionLine> lines;

  /// Creates a [JournalEntry].
  JournalEntry({
    required this.id,
    required this.description,
    required this.date,
    required this.lines,
  });

  /// Whether the journal entry is balanced (debits equal credits).
  bool get isBalanced => (totalDebit - totalCredit).abs() < 0.01;

  /// The sum of all credit amounts in this entry.
  double get totalCredit => lines
      .where((l) => l.type == TransactionType.credit)
      .fold(0, (sum, l) => sum + l.amount);

  /// The sum of all debit amounts in this entry.
  double get totalDebit => lines
      .where((l) => l.type == TransactionType.debit)
      .fold(0, (sum, l) => sum + l.amount);
}

/// Represents a general ledger account containing a history of transactions.
class LedgerAccount {
  /// The name of the ledger account (e.g., 'Cash', 'Revenue').
  final String name;

  /// The historical list of transaction lines affecting this account.
  final List<TransactionLine> transactions;

  /// Creates a [LedgerAccount].
  LedgerAccount({required this.name, required this.transactions});

  /// The current balance of the account, calculated from its transaction history.
  double get balance {
    double total = 0;
    for (var tx in transactions) {
      if (tx.type == TransactionType.debit) {
        total += tx.amount;
      } else {
        total -= tx.amount;
      }
    }
    return total;
  }
}

/// A single line item within a journal entry.
class TransactionLine {
  /// The name of the account being affected.
  final String accountName;

  /// The monetary amount of the transaction.
  final double amount;

  /// Whether this line is a debit or a credit.
  final TransactionType type;

  /// Creates a [TransactionLine].
  TransactionLine({
    required this.accountName,
    required this.amount,
    required this.type,
  });
}

/// The type of an accounting transaction: either a debit or a credit.
enum TransactionType {
  /// Increases assets or expenses, decreases liabilities or equity.
  debit,

  /// Increases liabilities or equity, decreases assets or expenses.
  credit,
}
