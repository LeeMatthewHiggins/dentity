abstract class SparseArray<T> implements Iterable<T> {
  void operator []=(int index, T component);
  T? operator [](int index);
  void remove(int index);
  Iterable<int> get indices;
  Iterable<T> get values;
  void clear();
}

class SimpleSparseArray<T> implements SparseArray<T> {
  final Map<int, T> _data = {};

  @override
  void operator []=(int index, T component) {
    _data[index] = component;
  }

  @override
  T? operator [](int index) {
    return _data[index];
  }

  @override
  void remove(int index) {
    _data.remove(index);
  }

  @override
  Iterable<int> get indices => _data.keys;

  @override
  Iterable<T> get values => _data.values;

  @override
  int get length => _data.length;

  @override
  void clear() {
    _data.clear();
  }

  @override
  Iterator<T> get iterator => _data.values.iterator;

  @override
  bool any(bool Function(T element) test) => _data.values.any(test);

  @override
  bool contains(Object? element) => _data.containsValue(element);

  @override
  T elementAt(int index) => _data.values.elementAt(index);

  @override
  bool every(bool Function(T element) test) => _data.values.every(test);

  @override
  Iterable<R> expand<R>(Iterable<R> Function(T element) toElements) =>
      _data.values.expand(toElements);

  @override
  T get first => _data.values.first;

  @override
  T firstWhere(bool Function(T element) test, {T Function()? orElse}) =>
      _data.values.firstWhere(test, orElse: orElse);

  @override
  R fold<R>(R initialValue, R Function(R previousValue, T element) combine) =>
      _data.values.fold(initialValue, combine);

  @override
  Iterable<T> followedBy(Iterable<T> other) => _data.values.followedBy(other);

  @override
  void forEach(void Function(T element) action) => _data.values.forEach(action);

  @override
  bool get isEmpty => _data.isEmpty;

  @override
  bool get isNotEmpty => _data.isNotEmpty;

  @override
  String join([String separator = '']) => _data.values.join(separator);

  @override
  T get last => _data.values.last;

  @override
  T lastWhere(bool Function(T element) test, {T Function()? orElse}) =>
      _data.values.lastWhere(test, orElse: orElse);

  @override
  Iterable<R> map<R>(R Function(T element) convert) =>
      _data.values.map(convert);

  @override
  T reduce(T Function(T value, T element) combine) =>
      _data.values.reduce(combine);

  @override
  T get single => _data.values.single;

  @override
  T singleWhere(bool Function(T element) test, {T Function()? orElse}) =>
      _data.values.singleWhere(test, orElse: orElse);

  @override
  Iterable<T> skip(int count) => _data.values.skip(count);

  @override
  Iterable<T> skipWhile(bool Function(T value) test) =>
      _data.values.skipWhile(test);

  @override
  Iterable<T> take(int count) => _data.values.take(count);

  @override
  Iterable<T> takeWhile(bool Function(T value) test) =>
      _data.values.takeWhile(test);

  @override
  List<T> toList({bool growable = true}) =>
      _data.values.toList(growable: growable);

  @override
  Set<T> toSet() => _data.values.toSet();

  @override
  Iterable<T> where(bool Function(T element) test) => _data.values.where(test);

  @override
  Iterable<R> whereType<R>() => _data.values.whereType<R>();

  @override
  String toString() => _data.values.toString();

  @override
  Iterable<R> cast<R>() {
    return _data.values.cast<R>();
  }
}
