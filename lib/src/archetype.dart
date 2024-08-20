typedef Archetype = BigInt;

class ArchetypeManager {
  final Map<Type, int> _componentTypeToBitIndex = {};

  ArchetypeManager(Iterable<Type> types) {
    var bitIndex = 0;
    for (var componentType in types) {
      _componentTypeToBitIndex[componentType] = bitIndex++;
      assert(bitIndex < 64, 'Too many component types, rethink your life');
    }
  }

  Archetype getArchetype(Iterable<Type> componentTypes) {
    Archetype bitset = Archetype.zero;
    for (var componentType in componentTypes) {
      var bitIndex = _componentTypeToBitIndex[componentType];
      if (bitIndex != null) {
        bitset |= Archetype.one << bitIndex;
      }
    }
    return bitset;
  }

  Iterable<Type> getComponentTypes(Archetype archetype) {
    var componentTypes = <Type>[];
    for (var componentType in _componentTypeToBitIndex.keys) {
      var bitIndex = _componentTypeToBitIndex[componentType];
      if (bitIndex != null &&
          (archetype & (Archetype.one << bitIndex)) != BigInt.zero) {
        componentTypes.add(componentType);
      }
    }
    return componentTypes;
  }
}
