import 'package:dentity/src/archetype/archetype.dart';
import 'package:dentity/src/entity/entity.dart';
import 'package:dentity/src/sparse_list/sparse_list.dart';

abstract class Component extends Object implements Comparable {
  Component clone();
}

typedef ComponentListFactory = SparseList<Component> Function();

abstract class ComponentManagerListener {
  void onComponentAdded(Entity entity, Component component);
  void onComponentWillRemove(Entity entity, Component component);
  void onComponentReplaced(
    Entity entity,
    Component oldComponent,
    Component newComponent,
  );
}

abstract class ComponentManagerReadOnlyInterface {
  Iterable<Type> get componentTypes;
  T? getComponent<T extends Component>(Entity entity);
  Iterable<Component> getComponents(Entity entity);
  Component? getComponentByType(Type componentType, Entity entity);
  bool hasComponent<T>(Entity entity);
  bool hasComponentByType(Entity entity, Type type);
  Iterable<T> getComponentsOfType<T extends Component>();
}

abstract class ComponentManagerInterface
    extends ComponentManagerReadOnlyInterface {
  void addComponents(Entity entity, Iterable<Component> components);
  void removeAllComponents(Entity entity);
  void removeComponentsByType(Entity entity, Iterable<Type> componentTypes);
  void removeComponentByType<T extends Component>(Entity entity);
}

class ComponentManager
    implements ComponentManagerInterface, ComponentManagerListener {
  final Map<Type, SparseList<Component>> _componentArrays = {};
  late final List<SparseList<Component>?> _indexedComponentArrays;
  final Map<Type, int> _typeIndexCache = {};
  late final Map<Type, ComponentListFactory> _componentArrayFactories;
  late ArchetypeManagerInterface _archetypeManager;
  ArchetypeManagerInterface get archetypeManager => _archetypeManager;
  final List<ComponentManagerListener> _observers = [];

  ComponentManager({
    Map<Type, ComponentListFactory> componentArrayFactories = const {},
    required ArchetypeManagerInterface Function(Iterable<Type>)
        archetypeManagerFactory,
  }) {
    _componentArrayFactories = componentArrayFactories;
    _archetypeManager = archetypeManagerFactory(_componentArrayFactories.keys);

    final maxIndex = _componentArrayFactories.keys
        .map((type) => _archetypeManager.getTypeIndex(type) ?? -1)
        .fold<int>(-1, (max, index) => index > max ? index : max);

    _indexedComponentArrays = List.filled(maxIndex + 1, null);

    for (var entry in _componentArrayFactories.entries) {
      final list = entry.value();
      _componentArrays[entry.key] = list;
      final index = _archetypeManager.getTypeIndex(entry.key);
      if (index != null) {
        _indexedComponentArrays[index] = list;
        _typeIndexCache[entry.key] = index;
      }
    }
  }

  @pragma('vm:prefer-inline')
  SparseList<Component>? _getComponentArray(Type type) {
    final index = _archetypeManager.getTypeIndex(type);
    if (index != null && index < _indexedComponentArrays.length) {
      return _indexedComponentArrays[index];
    }
    return _componentArrays[type];
  }

  @pragma('vm:prefer-inline')
  @override
  T? getComponent<T extends Component>(Entity entity) {
    final index = _typeIndexCache[T];
    if (index != null) {
      return _indexedComponentArrays[index]?[entity] as T?;
    }
    return _componentArrays[T]?[entity] as T?;
  }

  @override
  Iterable<Component> getComponents(Entity entity) sync* {
    for (var componentArray in _componentArrays.values) {
      final component = componentArray[entity];
      if (component != null) yield component;
    }
  }

  @pragma('vm:prefer-inline')
  @override
  Component? getComponentByType(Type componentType, Entity entity) =>
      _getComponentArray(componentType)?[entity];

  @override
  Iterable<T> getComponentsOfType<T extends Component>() {
    final componentArray = _getComponentArray(T);
    if (componentArray == null) {
      return [];
    }
    return componentArray.values.cast<T>();
  }

  @override
  Iterable<Type> get componentTypes => _componentArrays.keys;

  @pragma('vm:prefer-inline')
  @override
  bool hasComponentByType(Entity entity, Type type) =>
      _getComponentArray(type)?[entity] != null;

  @pragma('vm:prefer-inline')
  @override
  bool hasComponent<T>(Entity entity) => hasComponentByType(entity, T);

  @override
  void addComponents(Entity entity, Iterable<Component> components) {
    for (var component in components) {
      final factory = _componentArrayFactories[component.runtimeType];
      if (factory == null) {
        throw ArgumentError(
            'No factory found for component type ${component.runtimeType}');
      }
      final componentType = component.runtimeType;
      final previousComponent = _componentArrays[componentType]?[entity];
      _componentArrays[componentType]?[entity] = component;
      if (previousComponent != null) {
        onComponentReplaced(entity, previousComponent, component);
      } else {
        onComponentAdded(entity, component);
      }
    }
  }

  @override
  void removeAllComponents(Entity entity) {
    for (var componentArray in _componentArrays.values) {
      final component = componentArray[entity];
      if (component == null) {
        continue;
      }
      onComponentWillRemove(entity, component);
      componentArray.remove(entity);
    }
  }

  @override
  void removeComponentsByType(Entity entity, Iterable<Type> componentTypes) {
    for (var componentType in componentTypes) {
      final componentArray = _getComponentArray(componentType);
      if (componentArray == null) {
        throw ArgumentError('Component type not found in entity ($entity)');
      }
      final component = componentArray[entity];
      if (component == null) {
        continue;
      }
      onComponentWillRemove(entity, component);
      componentArray.remove(entity);
    }
  }

  @override
  void removeComponentByType<T extends Component>(Entity entity) {
    final componentArray = _getComponentArray(T);
    if (componentArray == null) {
      throw ArgumentError('Component type not found in entity ($entity)');
    }
    final component = componentArray[entity];
    if (component == null) {
      return;
    }
    onComponentWillRemove(entity, component);
    componentArray.remove(entity);
  }

  @override
  void onComponentAdded(Entity entity, Component component) {
    for (var observer in _observers) {
      observer.onComponentAdded(entity, component);
    }
  }

  @override
  void onComponentWillRemove(Entity entity, Component component) {
    for (var observer in _observers) {
      observer.onComponentWillRemove(entity, component);
    }
  }

  @override
  void onComponentReplaced(
    Entity entity,
    Component oldComponent,
    Component newComponent,
  ) {
    for (var observer in _observers) {
      observer.onComponentReplaced(
        entity,
        oldComponent,
        newComponent,
      );
    }
  }
}
