import 'package:dentity/src/archetype.dart';
import 'package:dentity/src/entity.dart';
import 'package:dentity/src/sparse_array.dart';

typedef Component = Object;

abstract class ComponentsInterface {
  T? getComponent<T extends Component>(Entity entity);
  Component? getComponentByType(Type componentType, Entity entity);
  Iterable<Type> get componentTypes;
  bool hasComponent(Entity entity, Type type);
}

class ReadonlyComponentManager implements ComponentsInterface {
  final Map<Type, SparseArray<Component>> _componentArrays = {};
  //final Map<Type, int> _componentTypeToBitIndex = {};
  ReadonlyComponentManager();

  @override
  T? getComponent<T extends Component>(Entity entity) {
    var componentType = T;
    return getComponentByType(componentType, entity) as T?;
  }

  @override
  Component? getComponentByType(Type componentType, Entity entity) {
    var componentArray = _componentArrays[componentType];
    return componentArray?[entity];
  }

  @override
  Iterable<Type> get componentTypes => _componentArrays.keys;

  @override
  bool hasComponent(Entity entity, Type type) {
    return _componentArrays[type]?[entity] != null;
  }
}

typedef ComponentArrayFactory = SparseArray<Component> Function();

class ComponentManager extends ReadonlyComponentManager {
  late final Map<Type, ComponentArrayFactory> _componentArrayFactories;
  late ArchetypeManager _archetypeManager;
  ArchetypeManager get archetypeManager => _archetypeManager;

  ComponentManager({
    Map<Type, ComponentArrayFactory> componentArrayFactories = const {},
  }) {
    _componentArrayFactories = componentArrayFactories;
    _archetypeManager = ArchetypeManager(_componentArrayFactories.keys);
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
        () => factory!(),
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
