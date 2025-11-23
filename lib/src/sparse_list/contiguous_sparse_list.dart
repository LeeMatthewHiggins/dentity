import 'package:dentity/dentity.dart';

const int _defaultPreallocateSize = 16384;
const int _defaultGrowStep = 8192;

class ContiguousSparseList<T> extends SparseList<T> {
  late List<T?> _data;
  late Set<int> _indices;
  final int _growStep;

  ContiguousSparseList({
    int preallocateSize = _defaultPreallocateSize,
    int growStep = _defaultGrowStep,
  }) : _growStep = growStep {
    _data = List<T?>.filled(preallocateSize, null, growable: false);
    _indices = Set<int>.identity();
  }

  void _ensureCapacity(int index) {
    if (index < _data.length) return;

    if (_growStep == 0) {
      throw StateError(
        'Cannot grow list beyond preallocated size ${_data.length}. '
        'Attempted to access index $index. '
        'Set growStep > 0 to allow growth.',
      );
    }

    final requiredSize = index + 1;
    final newSize = ((requiredSize / _growStep).ceil() * _growStep).toInt();
    final newData = List<T?>.filled(newSize, null, growable: false);

    for (var i = 0; i < _data.length; i++) {
      newData[i] = _data[i];
    }

    _data = newData;
  }

  @pragma('vm:prefer-inline')
  @override
  void operator []=(int index, T component) {
    _ensureCapacity(index);
    _data[index] = component;
    _indices.add(index);
  }

  @pragma('vm:prefer-inline')
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
    for (final index in _indices) {
      _data[index] = null;
    }
    _indices.clear();
  }

  @override
  Iterator<T> get iterator => values.iterator;

  @override
  int get length => _indices.length;

  @override
  bool contains(Object? element) {
    for (final index in _indices) {
      if (_data[index] == element) return true;
    }
    return false;
  }

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

  int get capacity => _data.length;
}
