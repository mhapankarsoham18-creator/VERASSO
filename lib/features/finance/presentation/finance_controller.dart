import 'package:flutter_riverpod/legacy.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/features/finance/data/finance_repository.dart';
import 'package:verasso/features/finance/models/accounting_model.dart';

/// Provides access to the [FinanceController] and its [FinanceState].
final financeControllerProvider =
    StateNotifierProvider<FinanceController, FinanceState>((ref) {
  return FinanceController(ref.watch(financeRepositoryProvider));
});

/// Presentation-layer controller for finance and accounting views.
///
/// This controller orchestrates loading journal entries and ledger summaries
/// from [FinanceRepository] and exposes them as immutable [FinanceState]
/// objects for widgets to consume.
class FinanceController extends StateNotifier<FinanceState> {
  final FinanceRepository _repo;

  /// Creates a new [FinanceController] and immediately triggers an initial
  /// [refresh] of the finance data.
  FinanceController(this._repo) : super(FinanceState()) {
    refresh();
  }

  /// Adds a new [entry] to the journal and refreshes the local state.
  Future<void> addJournalEntry(JournalEntry entry) async {
    await _repo.addEntry(entry);
    await refresh();
  }

  /// Reloads journal entries and ledger summaries from Supabase.
  ///
  /// Sets [FinanceState.isLoading] while the refresh is in progress and
  /// gracefully logs errors without throwing to the UI layer.
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    try {
      final journal = await _repo.getJournal();
      final ledgers = await _repo.getLedgers();
      state = state.copyWith(
        journal: journal,
        ledgers: ledgers,
        isLoading: false,
      );
    } catch (e) {
      AppLogger.info('Error refreshing finance data: $e');
      state = state.copyWith(isLoading: false);
    }
  }
}

/// Immutable state for finance views, including journal and ledger data.
class FinanceState {
  /// The list of recorded journal entries.
  final List<JournalEntry> journal;

  /// A map of account names to their respective ledger details.
  final Map<String, LedgerAccount> ledgers;

  /// Whether the finance data is currently being fetched or updated.
  final bool isLoading;

  /// Creates a [FinanceState] instance.
  FinanceState({
    this.journal = const [],
    this.ledgers = const {},
    this.isLoading = false,
  });

  /// Creates a copy of this [FinanceState] with the given fields replaced.
  FinanceState copyWith({
    List<JournalEntry>? journal,
    Map<String, LedgerAccount>? ledgers,
    bool? isLoading,
  }) {
    return FinanceState(
      journal: journal ?? this.journal,
      ledgers: ledgers ?? this.ledgers,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
