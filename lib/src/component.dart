import 'package:dentity/src/entity.dart';
import 'package:dentity/src/sparse_array.dart';

typedef Component = Object;

typedef Archetype = BigInt;

class ReadonlyComponentManager {
  final Map<Type, SparseArray<Component>> _componentArrays = {};
  final Map<Type, int> _componentTypeToBitIndex = {};
  final Map<Entity, Archetype> _entityByArchetype = {};
  final Map<Archetype, Set<Entity>> _entitiesByArchetype = {};
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

  /* Iterable<Entity> get entities {
    var entities = <Entity>{};
    for (var componentArray in _componentArrays.values) {
      entities.addAll(componentArray.indices);
    }
    return entities;
  }*/

  bool hasComponent(Entity entity, Type type) {
    return _componentArrays[type]?[entity] != null;
  }

  Archetype? getArchetype(Entity entity) {
    return _entityByArchetype[entity];
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

  Iterable<Entity> getEntitiesForArchetype(Archetype archetype) {
    return _entitiesByArchetype[archetype] ?? {};
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

  void addComponent(
    Entity entity,
    Component component, {
    bool updateArchetype = true,
  }) {
    final factory = _componentArrayFactories[component.runtimeType];
    assert(factory != null,
        'No factory found for component type ${component.runtimeType}');
    var componentType = component.runtimeType;
    _componentArrays.putIfAbsent(
      componentType,
      () => factory!(componentType),
    )[entity] = component;
    if (updateArchetype) {
      final newArhcetype = getArchetypeForComponentTypes(
        _componentArrays.keys,
      );
      _updateAchetype(entity, newArhcetype);
    }
  }

  void addComponents(Entity entity, Iterable<Component> components) {
    for (var component in components) {
      addComponent(entity, component, updateArchetype: false);
    }
    final newArhcetype = getArchetypeForComponentTypes(
      components.map((c) => c.runtimeType),
    );
    _updateAchetype(entity, newArhcetype);
  }

  void removeAllComponents(Entity entity) {
    _entitiesByArchetype[getArchetype(entity)]?.remove(entity);
    for (var componentArray in _componentArrays.values) {
      componentArray.remove(entity);
    }
    _entityByArchetype.remove(entity);
  }

  void removeComponent<T extends Component>(Entity entity,
      {bool updateArchetype = true}) {
    var componentType = T;
    var componentArray = _componentArrays[componentType];
    assert(
        componentArray != null, 'Component type not found in entity ($entity)');
    componentArray?.remove(entity);
    if (updateArchetype) {
      final newArhcetype = getArchetypeForComponentTypes(
        _componentArrays.keys,
      );
      _updateAchetype(entity, newArhcetype);
    }
  }

  void _updateAchetype(Entity entity, Archetype newArhcetype) {
    final previousAchetype = getArchetype(entity);
    _entityByArchetype[entity] = newArhcetype;
    if (previousAchetype != newArhcetype) {
      _entitiesByArchetype.putIfAbsent(newArhcetype, () => {}).add(entity);
      _entitiesByArchetype[previousAchetype]?.remove(entity);
    }
  }
}
