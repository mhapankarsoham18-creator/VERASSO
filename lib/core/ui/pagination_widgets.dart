import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Infinite scroll load indicator displayed at the bottom of a list.
class InfiniteScrollIndicator extends StatelessWidget {
  /// Whether more items are currently being fetched.
  final bool isLoading;

  /// Whether there are more items remaining to be loaded.
  final bool hasMore;

  /// Creates an [InfiniteScrollIndicator].
  const InfiniteScrollIndicator({
    super.key,
    required this.isLoading,
    required this.hasMore,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasMore) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'No more items to load',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ),
      );
    }

    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 8),
              Text(
                'Loading more...',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

/// Pagination controls widget for displaying pagination UI.
class PaginationControls extends StatelessWidget {
  /// Whether there are more items to load beyond the current set.
  final bool hasMore;

  /// Whether a load operation is currently in progress.
  final bool isLoading;

  /// The current page index (0-indexed).
  final int currentPage;

  /// The total number of pages available.
  final int totalPages;

  /// Callback executed when the "Load More" button is pressed.
  final VoidCallback onLoadMore;

  /// Callback executed for navigating to the next page.
  final VoidCallback? onNextPage;

  /// Callback executed for navigating to the previous page.
  final VoidCallback? onPreviousPage;

  /// Creates [PaginationControls].
  const PaginationControls({
    super.key,
    required this.hasMore,
    required this.isLoading,
    this.currentPage = 0,
    this.totalPages = 0,
    required this.onLoadMore,
    this.onNextPage,
    this.onPreviousPage,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasMore && currentPage > 0) {
      // Show "No more posts" message at the end
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: Text(
            'No more posts',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ),
      );
    }

    if (!hasMore && currentPage == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
                onPressed: onLoadMore,
                icon: const Icon(LucideIcons.chevronDown),
                label: const Text('Load More'),
              ),
      ),
    );
  }
}

/// Pagination footer with explicit page numbers and navigation buttons.
class PaginationFooter extends StatelessWidget {
  /// The current active page index.
  final int currentPage;

  /// The total number of pages in the result set.
  final int totalPages;

  /// Callback executed to navigate to the previous page.
  final VoidCallback onPreviousPage;

  /// Callback executed to navigate to the next page.
  final VoidCallback onNextPage;

  /// Whether a page transition is currently loading.
  final bool isLoading;

  /// Creates a [PaginationFooter].
  const PaginationFooter({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPreviousPage,
    required this.onNextPage,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: currentPage > 0 && !isLoading ? onPreviousPage : null,
            icon: const Icon(LucideIcons.chevronLeft),
            label: const Text('Previous'),
          ),
          Text(
            'Page ${currentPage + 1} of ${totalPages.clamp(1, totalPages)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          ElevatedButton.icon(
            onPressed:
                currentPage < totalPages - 1 && !isLoading ? onNextPage : null,
            icon: const Icon(LucideIcons.chevronRight),
            label: const Text('Next'),
          ),
        ],
      ),
    );
  }
}
