abstract class SparseList<T> extends Iterable<T> {
  void operator []=(int index, T component);
  T? operator [](int index);
  void remove(int index);
  Iterable<int> get indices;
  Iterable<T> get values;
  void clear();
}
