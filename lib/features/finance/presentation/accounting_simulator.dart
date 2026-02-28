import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../../../core/services/tutorial_service.dart';
import '../../../core/ui/tutorial_overlay.dart';
import '../../gamification/presentation/user_stats_controller.dart';
import '../models/accounting_model.dart';
import '../tutorials/accounting_tutorial.dart';
import 'finance_controller.dart';

/// Interactive double-entry accounting sandbox for learning journal entries,
/// ledgers, trial balances, and statements.
class AccountingSimulator extends ConsumerStatefulWidget {
  /// Creates an [AccountingSimulator] instance.
  const AccountingSimulator({super.key});

  @override
  ConsumerState<AccountingSimulator> createState() =>
      _AccountingSimulatorState();
}

class _AccountingSimulatorState extends ConsumerState<AccountingSimulator>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financeControllerProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Accounting Simulator'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.helpCircle),
            onPressed: _showTutorial,
            tooltip: 'Show Tutorial',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Journal'),
            Tab(text: 'Ledgers'),
            Tab(text: 'Trial Balance'),
            Tab(text: 'Statements'),
          ],
        ),
      ),
      body: LiquidBackground(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildJournalTab(state),
            _buildLedgerTab(state),
            _buildTrialBalanceTab(state),
            _buildStatementsTab(state),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEntryDialog(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(LucideIcons.plus),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final completed = await TutorialService.isTutorialCompleted(
          TutorialIds.accountingSimulator);
      if (!completed && mounted) {
        _showTutorial();
      }
    });
  }

  Widget _buildJournalTab(FinanceState state) {
    if (state.journal.isEmpty) {
      return const Center(
          child: Text('No journal entries yet.',
              style: TextStyle(color: Colors.white70)));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 120, left: 16, right: 16, bottom: 80),
      itemCount: state.journal.length,
      itemBuilder: (context, index) {
        final entry = state.journal[index];
        return GlassContainer(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.description,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    '${entry.date.day}/${entry.date.month}/${entry.date.year}',
                    style: const TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                ],
              ),
              const Divider(color: Colors.white24),
              ...entry.lines.map((line) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            line.accountName,
                            style: TextStyle(
                              color: line.type == TransactionType.debit
                                  ? Colors.white
                                  : Colors.white70,
                              fontWeight: line.type == TransactionType.debit
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              decoration: line.type == TransactionType.credit
                                  ? TextDecoration.none
                                  : null,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            line.type == TransactionType.debit
                                ? line.amount.toStringAsFixed(2)
                                : '',
                            textAlign: TextAlign.right,
                            style: const TextStyle(color: Colors.greenAccent),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            line.type == TransactionType.credit
                                ? line.amount.toStringAsFixed(2)
                                : '',
                            textAlign: TextAlign.right,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLedgerLine(TransactionLine tx) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Ref.',
              style: TextStyle(fontSize: 10, color: Colors.white38)),
          Text(tx.amount.toStringAsFixed(2),
              style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildLedgerTab(FinanceState state) {
    if (state.ledgers.isEmpty) {
      return const Center(
          child: Text('Add journal entries to see ledgers.',
              style: TextStyle(color: Colors.white70)));
    }

    return ListView(
      padding: const EdgeInsets.only(top: 120, left: 16, right: 16, bottom: 80),
      children:
          state.ledgers.entries.map((e) => _buildTAccount(e.value)).toList(),
    );
  }

  Widget _buildStatementRow(String label, double amount, Color color,
      {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
                color: color,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal),
          ),
        ],
      ),
    );
  }

  Widget _buildStatementsTab(FinanceState state) {
    if (state.ledgers.isEmpty) {
      return const Center(
          child: Text('No transactions yet.',
              style: TextStyle(color: Colors.white70)));
    }

    // Simplified Income Statement (Revenue - Expenses = Net Income)
    double revenue = 0;
    double expenses = 0;

    // Categorize accounts (simplified)
    for (var account in state.ledgers.values) {
      if (account.name.toLowerCase().contains('sales') ||
          account.name.toLowerCase().contains('revenue') ||
          account.name.toLowerCase().contains('income')) {
        revenue += account.balance.abs();
      } else if (account.name.toLowerCase().contains('expense') ||
          account.name.toLowerCase().contains('cost')) {
        expenses += account.balance.abs();
      }
    }

    final netIncome = revenue - expenses;

    // Simplified Balance Sheet
    double assets = 0;
    double liabilities = 0;
    double equity = netIncome;

    for (var account in state.ledgers.values) {
      if (account.name.toLowerCase().contains('cash') ||
          account.name.toLowerCase().contains('asset') ||
          account.name.toLowerCase().contains('receivable')) {
        assets += account.balance >= 0 ? account.balance : 0;
      } else if (account.name.toLowerCase().contains('payable') ||
          account.name.toLowerCase().contains('liability')) {
        liabilities += account.balance.abs();
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 120, left: 16, right: 16, bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Income Statement
          const Text('Income Statement',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GlassContainer(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildStatementRow('Revenue', revenue, Colors.greenAccent),
                _buildStatementRow('Expenses', expenses, Colors.orangeAccent),
                const Divider(color: Colors.white24),
                _buildStatementRow('Net Income', netIncome,
                    netIncome >= 0 ? Colors.greenAccent : Colors.redAccent,
                    bold: true),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Balance Sheet
          const Text('Balance Sheet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GlassContainer(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Assets',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blueAccent)),
                const SizedBox(height: 8),
                _buildStatementRow('Total Assets', assets, Colors.blueAccent),
                const SizedBox(height: 16),
                const Text('Liabilities',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.orangeAccent)),
                const SizedBox(height: 8),
                _buildStatementRow(
                    'Total Liabilities', liabilities, Colors.orangeAccent),
                const SizedBox(height: 16),
                const Text('Equity',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.purpleAccent)),
                const SizedBox(height: 8),
                _buildStatementRow(
                    'Retained Earnings', equity, Colors.purpleAccent),
                const Divider(color: Colors.white24),
                _buildStatementRow('Total Liabilities + Equity',
                    liabilities + equity, Colors.white,
                    bold: true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Note: This is a simplified demonstration. Actual financial statements require proper account classification.',
            style: TextStyle(
                fontSize: 11,
                color: Colors.white54,
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildTAccount(LedgerAccount account) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(account.name,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Container(height: 2, color: Colors.white24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Debit side
              Expanded(
                child: Column(
                  children: account.transactions
                      .where((tx) => tx.type == TransactionType.debit)
                      .map((tx) => _buildLedgerLine(tx))
                      .toList(),
                ),
              ),
              Container(
                  width: 2, height: 100, color: Colors.white24), // Center line
              // Credit side
              Expanded(
                child: Column(
                  children: account.transactions
                      .where((tx) => tx.type == TransactionType.credit)
                      .map((tx) => _buildLedgerLine(tx))
                      .toList(),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Balance:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                account.balance.toStringAsFixed(2),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: account.balance >= 0
                      ? Colors.greenAccent
                      : Colors.redAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrialBalanceTab(FinanceState state) {
    if (state.ledgers.isEmpty) {
      return const Center(
          child: Text('No ledger accounts yet.',
              style: TextStyle(color: Colors.white70)));
    }

    double totalDebit = 0;
    double totalCredit = 0;

    return ListView(
      padding: const EdgeInsets.only(top: 120, left: 16, right: 16, bottom: 80),
      children: [
        const Text('Trial Balance',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              const Row(
                children: [
                  Expanded(
                      flex: 2,
                      child: Text('Account',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12))),
                  Expanded(
                      child: Text('Debit',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12))),
                  Expanded(
                      child: Text('Credit',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12))),
                ],
              ),
              const Divider(color: Colors.white24),
              // Accounts
              ...state.ledgers.values.map((account) {
                final balance = account.balance;
                if (balance >= 0) {
                  totalDebit += balance;
                } else {
                  totalCredit += balance.abs();
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text(account.name)),
                      Expanded(
                        child: Text(
                          balance >= 0 ? balance.toStringAsFixed(2) : '',
                          textAlign: TextAlign.right,
                          style: const TextStyle(color: Colors.greenAccent),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          balance < 0 ? balance.abs().toStringAsFixed(2) : '',
                          textAlign: TextAlign.right,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(color: Colors.white24),
              // Totals
              Row(
                children: [
                  const Expanded(
                      flex: 2,
                      child: Text('Total',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(
                    child: Text(
                      totalDebit.toStringAsFixed(2),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.greenAccent),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      totalCredit.toStringAsFixed(2),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddEntryDialog(BuildContext context) {
    // Simplified entry dialog
    String desc = '';
    String acc1 = 'Cash';
    String acc2 = 'Sales';
    double amount = 1000;
    String errorMessage = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('New Journal Entry',
              style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (errorMessage.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.redAccent),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.redAccent, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMessage,
                            style: const TextStyle(
                                color: Colors.redAccent, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(color: Colors.white70),
                    hintText: 'e.g., Sale of goods',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    desc = v;
                    setDialogState(() => errorMessage = '');
                  },
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Debit Account',
                    labelStyle: TextStyle(color: Colors.white70),
                    hintText: 'Account to debit',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(text: acc1),
                  onChanged: (v) {
                    acc1 = v;
                    setDialogState(() => errorMessage = '');
                  },
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Credit Account',
                    labelStyle: TextStyle(color: Colors.white70),
                    hintText: 'Account to credit',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(text: acc2),
                  onChanged: (v) {
                    acc2 = v;
                    setDialogState(() => errorMessage = '');
                  },
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    labelStyle: TextStyle(color: Colors.white70),
                    hintText: 'Enter amount',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: OutlineInputBorder(),
                    prefixText: '\$ ',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    amount = double.tryParse(v) ?? 0;
                    setDialogState(() => errorMessage = '');
                  },
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('💡 Tip:',
                          style: TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text(
                        'Debits increase assets/expenses, Credits increase liabilities/revenue.',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Validation
                if (desc.trim().isEmpty) {
                  setDialogState(
                      () => errorMessage = 'Description is required');
                  return;
                }
                if (acc1.trim().isEmpty) {
                  setDialogState(
                      () => errorMessage = 'Debit account is required');
                  return;
                }
                if (acc2.trim().isEmpty) {
                  setDialogState(
                      () => errorMessage = 'Credit account is required');
                  return;
                }
                if (acc1.trim().toLowerCase() == acc2.trim().toLowerCase()) {
                  setDialogState(() => errorMessage =
                      'Debit and Credit accounts must be different');
                  return;
                }
                if (amount <= 0) {
                  setDialogState(
                      () => errorMessage = 'Amount must be greater than zero');
                  return;
                }

                final entry = JournalEntry(
                  id: DateTime.now().toString(),
                  description: desc.trim(),
                  date: DateTime.now(),
                  lines: [
                    TransactionLine(
                        accountName: acc1.trim(),
                        amount: amount,
                        type: TransactionType.debit),
                    TransactionLine(
                        accountName: acc2.trim(),
                        amount: amount,
                        type: TransactionType.credit),
                  ],
                );

                try {
                  ref
                      .read(financeControllerProvider.notifier)
                      .addJournalEntry(entry);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Journal entry added successfully!'),
                        backgroundColor: Colors.green),
                  );
                } catch (e) {
                  setDialogState(() => errorMessage = 'Error: ${e.toString()}');
                }
              },
              child: const Text('Add Entry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTutorial() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TutorialOverlay(
        steps: accountingTutorialSteps,
        onComplete: () {
          TutorialService.markTutorialCompleted(
              TutorialIds.accountingSimulator);
          ref
              .read(userStatsProvider.notifier)
              .addXP(200); // Reward for completion
        },
      ),
    );
  }
}
