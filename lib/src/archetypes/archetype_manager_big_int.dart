import 'package:dentity/dentity.dart';

class ArchetypeManagerBigInt implements ArchetypeManagerInterface {
  final Map<Type, int> _componentTypeToBitIndex = {};

  ArchetypeManagerBigInt(Iterable<Type> types) {
    var bitIndex = 0;
    for (var componentType in types) {
      _componentTypeToBitIndex[componentType] = bitIndex++;
    }
  }

  @override
  Archetype getArchetype(Iterable<Type> componentTypes) {
    BigInt bitset = BigInt.zero;
    for (var componentType in componentTypes) {
      var bitIndex = _componentTypeToBitIndex[componentType];
      if (bitIndex != null) {
        bitset |= BigInt.one << bitIndex;
      }
    }
    return bitset;
  }

  @override
  Iterable<Type> getComponentTypes(Archetype archetype) {
    final archetypeBigInt = archetype as BigInt;
    var componentTypes = <Type>[];
    for (var componentType in _componentTypeToBitIndex.keys) {
      var bitIndex = _componentTypeToBitIndex[componentType];
      if (bitIndex != null &&
          (archetypeBigInt & (BigInt.one << bitIndex)) != BigInt.zero) {
        componentTypes.add(componentType);
      }
    }
    return componentTypes;
  }

  @override
  bool isSubtype(Archetype a, Archetype b) {
    return (a as BigInt) & (b as BigInt) == b;
  }

  @override
  bool isSupertype(Archetype a, Archetype b) {
    return (a as BigInt) & (b as BigInt) == a;
  }
}
