import 'package:flutter_riverpod/legacy.dart';

/// Comments pagination provider
final commentsPaginationProvider =
    StateNotifierProvider<PaginationNotifier, PaginationState>((ref) {
  return PaginationNotifier(pageSize: 15);
});

/// Feed-specific pagination provider
final feedPaginationProvider =
    StateNotifierProvider<PaginationNotifier, PaginationState>((ref) {
  return PaginationNotifier(pageSize: 20);
});

/// Generic pagination provider factory
final paginationProvider =
    StateNotifierProvider<PaginationNotifier, PaginationState>((ref) {
  return PaginationNotifier();
});

/// Profile-specific pagination provider (followers/following)
final profilePaginationProvider =
    StateNotifierProvider<PaginationNotifier, PaginationState>((ref) {
  return PaginationNotifier(pageSize: 20);
});

/// Search results pagination provider
final searchPaginationProvider =
    StateNotifierProvider<PaginationNotifier, PaginationState>((ref) {
  return PaginationNotifier(pageSize: 20);
});

/// Notifier for managing pagination state
class PaginationNotifier extends StateNotifier<PaginationState> {
  /// Creates a [PaginationNotifier] with an optional [pageSize].
  PaginationNotifier({int pageSize = 20})
      : super(PaginationState(pageSize: pageSize));

  /// Go to specific page
  /// Navigates to a specific [pageNumber].
  void goToPage(int pageNumber) {
    if (pageNumber >= 0 && pageNumber < state.totalPages) {
      state = state.copyWith(currentPage: pageNumber);
    }
  }

  /// Move to next page if available
  /// Advances to the next page if more items are available.
  void nextPage() {
    if (state.hasMore && !state.isLoading) {
      state = state.copyWith(currentPage: state.currentPage + 1);
    }
  }

  /// Move to previous page if available
  /// Returns to the previous page if not already on the first.
  void previousPage() {
    if (!state.isFirstPage) {
      state = state.copyWith(currentPage: state.currentPage - 1);
    }
  }

  /// Reset pagination to first page
  /// Resets the pagination state to the first page.
  void reset() {
    state = PaginationState(pageSize: state.pageSize);
  }

  /// Set error
  /// Sets the state to an error with the provided [error] message.
  void setError(String error) {
    state = state.copyWith(error: error, isLoading: false);
  }

  /// Updates the pagination state with new [totalItems] and [hasMore] status.
  void updateResults({
    required int totalItems,
    required bool hasMore,
    String? error,
  }) {
    state = state.copyWith(
      totalItems: totalItems,
      hasMore: hasMore,
      isLoading: false,
      error: error,
    );
  }
}

/// Represents the state of pagination
class PaginationState {
  /// The currently active page index (0-indexed).
  final int currentPage;

  /// The number of items per page.
  final int pageSize;

  /// The total number of items across all pages.
  final int totalItems;

  /// Whether there are more items to be loaded.
  final bool hasMore;

  /// Whether a page load is currently in progress.
  final bool isLoading;

  /// Optional error message if the last load failed.
  final String? error;

  /// Creates an immutable [PaginationState] with the provided values.
  const PaginationState({
    this.currentPage = 0,
    this.pageSize = 20,
    this.totalItems = 0,
    this.hasMore = true,
    this.isLoading = false,
    this.error,
  });

  /// Whether the current page is the first page (0).
  bool get isFirstPage => currentPage == 0;

  /// Whether this is the last page of results based on [totalItems].
  bool get isLastPage => currentPage >= totalPages - 1;

  /// The calculated offset for API queries.
  int get offset => currentPage * pageSize;

  /// The total number of pages calculated from [totalItems] and [pageSize].
  int get totalPages => (totalItems / pageSize).ceil();

  /// Creates a copy of this state with the provided fields replaced.
  PaginationState copyWith({
    int? currentPage,
    int? pageSize,
    int? totalItems,
    bool? hasMore,
    bool? isLoading,
    String? error,
  }) {
    return PaginationState(
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      totalItems: totalItems ?? this.totalItems,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
