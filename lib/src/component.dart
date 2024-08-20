import 'package:dentity/src/archetype.dart';
import 'package:dentity/src/entity.dart';
import 'package:dentity/src/sparse_array.dart';

typedef Component = Object;
typedef ComponentArrayFactory = SparseArray<Component> Function();

abstract class ComponentsInterface {
  Iterable<Type> get componentTypes;
  T? getComponent<T extends Component>(Entity entity);
  Iterable<Component> getComponents(Entity entity);
  Component? getComponentByType(Type componentType, Entity entity);
  bool hasComponent<T>(Entity entity);
  bool hasComponentByType(Entity entity, Type type);
  void addComponents(Entity entity, Iterable<Component> components);
  Iterable<T> getAllComponents<T extends Component>();
  void removeAllComponents(Entity entity);
  void removeComponentsByType(Entity entity, Iterable<Type> componentTypes);
  void removeComponent<T extends Component>(Entity entity);
}

class ComponentManager implements ComponentsInterface {
  final Map<Type, SparseArray<Component>> _componentArrays = {};
  late final Map<Type, ComponentArrayFactory> _componentArrayFactories;
  late ArchetypeManager _archetypeManager;
  ArchetypeManager get archetypeManager => _archetypeManager;

  ComponentManager({
    Map<Type, ComponentArrayFactory> componentArrayFactories = const {},
  }) {
    _componentArrayFactories = componentArrayFactories;
    _archetypeManager = ArchetypeManager(_componentArrayFactories.keys);
  }

  @override
  T? getComponent<T extends Component>(Entity entity) {
    var componentType = T;
    return getComponentByType(componentType, entity) as T?;
  }

  @override
  Iterable<Component> getComponents(Entity entity) {
    return _componentArrays.values
        .map((componentArray) => componentArray[entity])
        .where((component) => component != null)
        .cast<Component>();
  }

  @override
  Component? getComponentByType(Type componentType, Entity entity) {
    var componentArray = _componentArrays[componentType];
    return componentArray?[entity];
  }

  @override
  Iterable<T> getAllComponents<T extends Component>() {
    var componentType = T;
    var componentArray = _componentArrays[componentType];
    return componentArray?.values.cast<T>() ?? [];
  }

  @override
  Iterable<Type> get componentTypes => _componentArrays.keys;

  @override
  bool hasComponentByType(Entity entity, Type type) {
    return _componentArrays[type]?[entity] != null;
  }

  @override
  bool hasComponent<T>(Entity entity) {
    return hasComponentByType(entity, T);
  }

  @override
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

  @override
  void removeAllComponents(Entity entity) {
    for (var componentArray in _componentArrays.values) {
      componentArray.remove(entity);
    }
  }

  @override
  void removeComponentsByType(Entity entity, Iterable<Type> componentTypes) {
    for (var componentType in componentTypes) {
      var componentArray = _componentArrays[componentType];
      assert(componentArray != null,
          'Component type not found in entity ($entity)');
      componentArray?.remove(entity);
    }
  }

  @override
  void removeComponent<T extends Component>(Entity entity) {
    var componentType = T;
    var componentArray = _componentArrays[componentType];
    assert(
        componentArray != null, 'Component type not found in entity ($entity)');
    componentArray?.remove(entity);
  }
}
