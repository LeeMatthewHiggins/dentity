typedef Archetype = BigInt;

class ArchetypeManager {
  final Map<Type, int> _componentTypeToBitIndex = {};

  ArchetypeManager(Iterable<Type> types) {
    var bitIndex = 0;
    for (var componentType in types) {
      _componentTypeToBitIndex[componentType] = bitIndex++;
    }
  }

  Archetype getArchetype(Iterable<Type> componentTypes) {
    Archetype bitset = BigInt.zero;
    for (var componentType in componentTypes) {
      var bitIndex = _componentTypeToBitIndex[componentType];
      if (bitIndex != null) {
        bitset |= BigInt.one << bitIndex;
      }
    }
    return bitset;
  }

  Iterable<Type> getComponentTypes(Archetype archetype) {
    var componentTypes = <Type>[];
    for (var componentType in _componentTypeToBitIndex.keys) {
      var bitIndex = _componentTypeToBitIndex[componentType];
      if (bitIndex != null &&
          (archetype & (BigInt.one << bitIndex)) != BigInt.zero) {
        componentTypes.add(componentType);
      }
    }
    return componentTypes;
  }
}
