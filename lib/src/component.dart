import 'package:dentity/src/entity.dart';
import 'package:dentity/src/sparse_array.dart';

typedef Component = Object;

typedef Archetype = BigInt;

class ReadonlyComponentManager {
  final Map<Type, SparseArray<Component>> _componentArrays = {};
  final Map<Type, int> _componentTypeToBitIndex = {};
  ReadonlyComponentManager();

  T? getComponent<T extends Component>(Entity entity) {
    var componentType = T;
    return getComponentByType(componentType, entity) as T?;
  }

  Component? getComponentByType(Type componentType, Entity entity) {
    var componentArray = _componentArrays[componentType];
    return componentArray?[entity];
  }

  Iterable<Type> get componentTypes => _componentArrays.keys;

  bool hasComponent(Entity entity, Type type) {
    return _componentArrays[type]?[entity] != null;
  }

  Archetype getArchetypeForComponentTypes(Iterable<Type> componentTypes) {
    Archetype bitset = Archetype.zero;
    for (var componentType in componentTypes) {
      var bitIndex = _componentTypeToBitIndex[componentType];
      if (bitIndex != null) {
        bitset |= Archetype.one << bitIndex;
      }
    }
    return bitset;
  }

  Iterable<Type> getComponentTypesForArchetype(Archetype archetype) {
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

typedef ComponentArrayFactory = SparseArray<Component> Function(Type);

class ComponentManager extends ReadonlyComponentManager {
  late final Map<Type, ComponentArrayFactory> _componentArrayFactories;

  ComponentManager({
    Map<Type, ComponentArrayFactory> componentArrayFactories = const {},
  }) {
    _componentArrayFactories = componentArrayFactories;
    var bitIndex = 0;
    for (var componentType in _componentArrayFactories.keys) {
      _componentArrays[componentType] =
          _componentArrayFactories[componentType]!(componentType);
      _componentTypeToBitIndex[componentType] = bitIndex++;
    }
  }

  void addComponents(Entity entity, Iterable<Component> components) {
    for (var component in components) {
      final factory = _componentArrayFactories[component.runtimeType];
      assert(component is! Type,
          'You must add an instance of a component, not the type of the component');
      assert(factory != null,
          'No factory found for component type ${component.runtimeType}');
      var componentType = component.runtimeType;
      _componentArrays.putIfAbsent(
        componentType,
        () => factory!(componentType),
      )[entity] = component;
    }
  }

  void removeAllComponents(Entity entity) {
    for (var componentArray in _componentArrays.values) {
      componentArray.remove(entity);
    }
  }

  void removeComponentsByType(Entity entity, Iterable<Type> componentTypes) {
    for (var componentType in componentTypes) {
      var componentArray = _componentArrays[componentType];
      assert(componentArray != null,
          'Component type not found in entity ($entity)');
      componentArray?.remove(entity);
    }
  }

  void removeComponent<T extends Component>(Entity entity) {
    var componentType = T;
    var componentArray = _componentArrays[componentType];
    assert(
        componentArray != null, 'Component type not found in entity ($entity)');
    componentArray?.remove(entity);
  }
}
