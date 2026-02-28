// Performance Optimization: QuickSort, MaxHeap, LazyLoading
// High-performance data structures for handling large datasets

import 'package:flutter/material.dart';

// ============================================================================
// LAZY LOADING PAGINATION
// ============================================================================
/// A controller for managing lazy-loaded paginated data sets.
class LazyLoadingController<T> {
  /// The number of items to fetch per page.
  final int pageSize;

  /// The function to call to fetch a specific page of items.
  final Future<List<T>> Function(int page) fetchPage;

  final List<T> _items = [];
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;

  /// Creates a [LazyLoadingController] instance.
  LazyLoadingController({
    required this.fetchPage,
    this.pageSize = 20,
  });

  /// Whether there are more items to be loaded.
  bool get hasMore => _hasMore;

  /// Whether the controller is currently loading items.
  bool get isLoading => _isLoading;

  /// The list of items loaded so far.
  List<T> get items => List.unmodifiable(_items);

  /// The total number of items loaded so far.
  int get totalLoaded => _items.length;

  /// Append item to end
  void append(T item) => _items.add(item);

  /// Load next page
  /// Returns true if new items were loaded
  Future<bool> loadNextPage() async {
    if (_isLoading || !_hasMore) return false;

    _isLoading = true;
    try {
      List<T> newItems = await fetchPage(_currentPage);

      if (newItems.isEmpty) {
        _hasMore = false;
        return false;
      }

      _items.addAll(newItems);
      _currentPage++;
      return true;
    } finally {
      _isLoading = false;
    }
  }

  /// Prepend item to beginning
  void prepend(T item) => _items.insert(0, item);

  /// Remove item at index
  void removeAt(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
    }
  }

  /// Reset and reload from beginning
  Future<void> reset() async {
    _items.clear();
    _currentPage = 0;
    _hasMore = true;
    _isLoading = false;
    await loadNextPage();
  }

  /// Update item at index
  void updateAt(int index, T item) {
    if (index >= 0 && index < _items.length) {
      _items[index] = item;
    }
  }
}

// ============================================================================
// INFINITE SCROLL LISTVIEW HELPER
// ============================================================================

/// A list view that implements lazy loading for paginated data.
class LazyLoadingListView<T> extends StatefulWidget {
  /// The controller that handles data loading and pagination.
  final LazyLoadingController<T> controller;

  /// A function that builds a widget for a given item index.
  final IndexedWidgetBuilder itemBuilder;

  /// An optional builder for the loading indicator at the end of the list.
  final WidgetBuilder? loadingBuilder;

  /// An optional builder for the widget to show when the list is empty.
  final WidgetBuilder? emptyBuilder;

  /// The scroll physics to use for the list view.
  final ScrollPhysics? physics;

  /// Creates a [LazyLoadingListView] instance.
  const LazyLoadingListView({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.physics,
  });

  @override
  State<LazyLoadingListView<T>> createState() => _LazyLoadingListViewState<T>();
}

// ============================================================================
// MAX HEAP IMPLEMENTATION
// ============================================================================
/// A binary max-heap implementation for priority-based data management.
class MaxHeap<T extends Comparable<T>> {
  final List<T> _items = [];

  /// Whether the heap is currently empty.
  bool get isEmpty => _items.isEmpty;

  /// The number of elements in the heap.
  int get size => _items.length;

  /// Extract maximum element - O(log n)
  T extractMax() {
    if (_items.isEmpty) throw Exception('Heap is empty');

    T max = _items[0];
    if (_items.length == 1) {
      _items.clear();
    } else {
      _items[0] = _items.removeLast();
      _bubbleDown(0);
    }
    return max;
  }

  /// Insert element - O(log n)
  void insert(T value) {
    _items.add(value);
    _bubbleUp(_items.length - 1);
  }

  /// Batch insert for multiple items - O(n)
  void insertAll(Iterable<T> values) {
    for (var value in values) {
      _items.add(value);
    }
    _heapify();
  }

  /// Peek at maximum without removing - O(1)
  T peekMax() {
    if (_items.isEmpty) throw Exception('Heap is empty');
    return _items[0];
  }

  /// Returns a list containing all elements in the heap.
  List<T> toList() => List.from(_items);

  void _bubbleDown(int index) {
    while (true) {
      int largest = index;
      int leftChild = 2 * index + 1;
      int rightChild = 2 * index + 2;

      if (leftChild < _items.length &&
          _items[leftChild].compareTo(_items[largest]) > 0) {
        largest = leftChild;
      }
      if (rightChild < _items.length &&
          _items[rightChild].compareTo(_items[largest]) > 0) {
        largest = rightChild;
      }

      if (largest != index) {
        _swap(index, largest);
        index = largest;
      } else {
        break;
      }
    }
  }

  void _bubbleUp(int index) {
    while (index > 0) {
      int parentIndex = (index - 1) ~/ 2;
      if (_items[index].compareTo(_items[parentIndex]) > 0) {
        _swap(index, parentIndex);
        index = parentIndex;
      } else {
        break;
      }
    }
  }

  void _heapify() {
    for (int i = _items.length ~/ 2 - 1; i >= 0; i--) {
      _bubbleDown(i);
    }
  }

  void _swap(int i, int j) {
    T temp = _items[i];
    _items[i] = _items[j];
    _items[j] = temp;
  }
}

// ============================================================================
// PRIORITY QUEUE (Min-Heap variant)
// ============================================================================
/// A priority queue implementation based on a binary min-heap.
class PriorityQueue<T> {
  final List<_HeapNode<T>> _heap = [];
  final int Function(T a, T b)? _comparator;

  /// Creates a [PriorityQueue] instance.
  PriorityQueue({int Function(T a, T b)? comparator})
      : _comparator = comparator;

  /// Whether the priority queue is currently empty.
  bool get isEmpty => _heap.isEmpty;

  /// The number of elements in the priority queue.
  int get size => _heap.length;

  /// Removes and returns the element with the highest priority (lowest priority value).
  T dequeue() {
    if (_heap.isEmpty) throw Exception('Queue is empty');
    T value = _heap[0].value;
    if (_heap.length == 1) {
      _heap.clear();
    } else {
      _heap[0] = _heap.removeLast();
      _bubbleDown(0);
    }
    return value;
  }

  /// Enqueues a value with a specific priority.
  void enqueue(T value, int priority) {
    _heap.add(_HeapNode(value, priority));
    _bubbleUp(_heap.length - 1);
  }

  /// Returns the element with the highest priority without removing it.
  T peek() {
    if (_heap.isEmpty) throw Exception('Queue is empty');
    return _heap[0].value;
  }

  void _bubbleDown(int index) {
    while (true) {
      int smallest = index;
      int leftChild = 2 * index + 1;
      int rightChild = 2 * index + 2;

      if (leftChild < _heap.length &&
          _compare(_heap[leftChild], _heap[smallest]) < 0) {
        smallest = leftChild;
      }
      if (rightChild < _heap.length &&
          _compare(_heap[rightChild], _heap[smallest]) < 0) {
        smallest = rightChild;
      }

      if (smallest != index) {
        _swap(index, smallest);
        index = smallest;
      } else {
        break;
      }
    }
  }

  void _bubbleUp(int index) {
    while (index > 0) {
      int parentIndex = (index - 1) ~/ 2;
      if (_compare(_heap[index], _heap[parentIndex]) < 0) {
        _swap(index, parentIndex);
        index = parentIndex;
      } else {
        break;
      }
    }
  }

  int _compare(_HeapNode<T> a, _HeapNode<T> b) {
    int priorityCompare = a.priority.compareTo(b.priority);
    if (priorityCompare != 0) return priorityCompare;
    if (_comparator != null) return _comparator(a.value, b.value);
    return 0;
  }

  void _swap(int i, int j) {
    _HeapNode<T> temp = _heap[i];
    _heap[i] = _heap[j];
    _heap[j] = temp;
  }
}

// ============================================================================
// QUICKSORT IMPLEMENTATION
// ============================================================================
/// An implementation of the QuickSort algorithm.
class QuickSort<T extends Comparable<T>> {
  /// In-place quicksort with O(n log n) average time complexity
  void sort(List<T> list, {int left = 0, int? right}) {
    right ??= list.length - 1;

    if (left < right) {
      int pivotIndex = _partition(list, left, right);
      sort(list, left: left, right: pivotIndex - 1);
      sort(list, left: pivotIndex + 1, right: right);
    }
  }

  /// Sort by custom comparator
  void sortBy(List<T> list, Comparable Function(T) keyFunction) {
    list.sort((a, b) => keyFunction(a).compareTo(keyFunction(b)));
  }

  int _partition(List<T> list, int left, int right) {
    // Use randomized pivot to avoid worst case
    int randomIndex = left + (right - left) ~/ 2;
    _swap(list, randomIndex, right);

    T pivot = list[right];
    int i = left - 1;

    for (int j = left; j < right; j++) {
      if (list[j].compareTo(pivot) <= 0) {
        i++;
        _swap(list, i, j);
      }
    }

    _swap(list, i + 1, right);
    return i + 1;
  }

  void _swap(List<T> list, int i, int j) {
    T temp = list[i];
    list[i] = list[j];
    list[j] = temp;
  }
}

class _HeapNode<T> {
  final T value;
  final int priority;
  _HeapNode(this.value, this.priority);
}

class _LazyLoadingListViewState<T> extends State<LazyLoadingListView<T>> {
  late ScrollController _scrollController;

  @override
  Widget build(BuildContext context) {
    if (widget.controller.items.isEmpty && !widget.controller.isLoading) {
      return widget.emptyBuilder?.call(context) ?? const SizedBox.shrink();
    }

    return ListView.builder(
      controller: _scrollController,
      physics: widget.physics,
      itemCount: widget.controller.items.length +
          (widget.controller.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= widget.controller.items.length) {
          return widget.loadingBuilder?.call(context) ??
              const Center(child: CircularProgressIndicator());
        }
        return widget.itemBuilder(context, index);
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      // User scrolled to bottom
      widget.controller.loadNextPage();
    }
  }
}
