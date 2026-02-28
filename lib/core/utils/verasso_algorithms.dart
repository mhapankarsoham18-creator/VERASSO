/// A Max-Heap implementation for prioritizing nodes and content.
class MaxHeap<T> {
  final List<T> _heap = [];
  final int Function(T, T) _compare;

  /// Creates a [MaxHeap] with a custom [compare] function.
  MaxHeap(this._compare);

  /// Returns true if the heap is empty.
  bool get isEmpty => _heap.isEmpty;

  /// Returns the number of elements in the heap.
  int get length => _heap.length;

  /// Removes and returns the maximum element from the heap.
  T? extractMax() {
    if (_heap.isEmpty) return null;
    if (_heap.length == 1) return _heap.removeLast();

    T max = _heap[0];
    _heap[0] = _heap.removeLast();
    _bubbleDown(0);
    return max;
  }

  /// Inserts a new element into the heap.
  void insert(T element) {
    _heap.add(element);
    _bubbleUp(_heap.length - 1);
  }

  /// Returns the maximum element without removing it.
  T? peekMax() => _heap.isNotEmpty ? _heap[0] : null;

  void _bubbleDown(int index) {
    while (true) {
      int leftChild = 2 * index + 1;
      int rightChild = 2 * index + 2;
      int largest = index;

      if (leftChild < _heap.length &&
          _compare(_heap[leftChild], _heap[largest]) > 0) {
        largest = leftChild;
      }

      if (rightChild < _heap.length &&
          _compare(_heap[rightChild], _heap[largest]) > 0) {
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
      if (_compare(_heap[index], _heap[parentIndex]) > 0) {
        _swap(index, parentIndex);
        index = parentIndex;
      } else {
        break;
      }
    }
  }

  void _swap(int i, int j) {
    T temp = _heap[i];
    _heap[i] = _heap[j];
    _heap[j] = temp;
  }
}

/// A collection of high-performance algorithms optimized for Verasso's data structures.
class VerassoAlgorithms {
  /// Sorts a list of [T] using the Quicksort algorithm.
  ///
  /// [T] must implement [Comparable] or a custom [compare] function must be provided.
  static void quicksort<T>(List<T> list,
      [int? left, int? right, int Function(T, T)? compare]) {
    left ??= 0;
    right ??= list.length - 1;
    compare ??= (a, b) => (a as Comparable).compareTo(b);

    if (left >= right) return;

    int pivotIndex = _partition(list, left, right, compare);
    quicksort(list, left, pivotIndex - 1, compare);
    quicksort(list, pivotIndex + 1, right, compare);
  }

  static int _partition<T>(
      List<T> list, int left, int right, int Function(T, T) compare) {
    T pivot = list[right];
    int i = left - 1;

    for (int j = left; j < right; j++) {
      if (compare(list[j], pivot) <= 0) {
        i++;
        _swap(list, i, j);
      }
    }

    _swap(list, i + 1, right);
    return i + 1;
  }

  static void _swap<T>(List<T> list, int i, int j) {
    T temp = list[i];
    list[i] = list[j];
    list[j] = temp;
  }
}
