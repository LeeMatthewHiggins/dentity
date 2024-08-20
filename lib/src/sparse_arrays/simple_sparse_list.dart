import 'package:dentity/dentity.dart';

class SimpleSparseList<T> extends SparseList<T> {
  final Map<int, T> _data = {};

  @override
  void operator []=(int index, T component) {
    _data[index] = component;
  }

  @override
  T? operator [](int index) => _data[index];

  @override
  void remove(int index) {
    _data.remove(index);
  }

  @override
  Iterable<int> get indices => _data.keys;

  @override
  Iterable<T> get values => _data.values;

  @override
  void clear() {
    _data.clear();
  }

  @override
  Iterator<T> get iterator => _data.values.iterator;

  @override
  int get length => _data.length;

  @override
  bool contains(Object? element) => _data.containsValue(element);

  @override
  T elementAt(int index) => _data.values.elementAt(index);

  @override
  Iterable<R> map<R>(R Function(T element) toElement) =>
      _data.values.map(toElement);

  @override
  List<T> toList({bool growable = true}) =>
      _data.values.toList(growable: growable);

  @override
  Set<T> toSet() => _data.values.toSet();
}
