import 'dart:collection';

import 'package:dentity/dentity.dart';

class ArchetypeManagerBigInt implements ArchetypeManagerInterface {
  final HashMap<Type, int> _componentTypeToBitIndex;
  final List<Type> _bitIndexToComponentType;

  ArchetypeManagerBigInt(Iterable<Type> types)
      : _componentTypeToBitIndex = HashMap(
          equals: identical,
          hashCode: identityHashCode,
        ),
        _bitIndexToComponentType = List.unmodifiable(types) {
    for (var bitIndex = 0; bitIndex < _bitIndexToComponentType.length; bitIndex++) {
      _componentTypeToBitIndex[_bitIndexToComponentType[bitIndex]] = bitIndex;
    }
  }

  @override
  Archetype getArchetype(Iterable<Type> componentTypes) {
    BigInt bitset = BigInt.zero;
    for (var componentType in componentTypes) {
      final bitIndex = _componentTypeToBitIndex[componentType];
      if (bitIndex != null) {
        bitset |= BigInt.one << bitIndex;
      }
    }
    return bitset;
  }

  @override
  Iterable<Type> getComponentTypes(Archetype archetype) {
    final archetypeBigInt = archetype as BigInt;
    final componentTypes = <Type>[];
    for (var bitIndex = 0; bitIndex < _bitIndexToComponentType.length; bitIndex++) {
      if ((archetypeBigInt & (BigInt.one << bitIndex)) != BigInt.zero) {
        componentTypes.add(_bitIndexToComponentType[bitIndex]);
      }
    }
    return componentTypes;
  }

  @pragma('vm:prefer-inline')
  @override
  bool isSubtype(Archetype a, Archetype b) {
    return (a as BigInt) & (b as BigInt) == b;
  }

  @pragma('vm:prefer-inline')
  @override
  bool isSupertype(Archetype a, Archetype b) {
    return (a as BigInt) & (b as BigInt) == a;
  }

  @override
  bool matches(Iterable<Type> componentTypes) {
    final archetype = getArchetype(componentTypes);
    return archetype == getArchetype(componentTypes);
  }

  @pragma('vm:prefer-inline')
  @override
  int? getTypeIndex(Type type) => _componentTypeToBitIndex[type];
}
