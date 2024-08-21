import 'package:dentity/dentity.dart';

class ContiguousSparseList<T> extends SparseList<T> {
  final List<T?> _data = [];
  final Set<int> _indices = {};

  @override
  void operator []=(int index, T component) {
    if (index >= _data.length) {
      _data.length = index + 1; // Expand list size if needed
    }
    _data[index] = component;
    _indices.add(index);
  }

  @override
  T? operator [](int index) {
    if (index >= _data.length) return null;
    return _data[index];
  }

  @override
  void remove(int index) {
    if (index < _data.length) {
      _data[index] = null;
      _indices.remove(index);
    }
  }

  @override
  Iterable<int> get indices => _indices;

  @override
  Iterable<T> get values => _indices.map((index) => _data[index]!);

  @override
  void clear() {
    _data.clear();
    _indices.clear();
  }

  @override
  Iterator<T> get iterator => values.iterator;

  @override
  int get length => _indices.length;

  @override
  bool contains(Object? element) => _data.contains(element);

  @override
  T elementAt(int index) {
    if (index >= length) throw RangeError.index(index, this);
    return values.elementAt(index);
  }

  @override
  List<T> toList({bool growable = true}) => values.toList(growable: growable);

  @override
  Set<T> toSet() => values.toSet();

  @override
  String toString() => values.toString();
}
