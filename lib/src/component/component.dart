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
  EntityComposition componentsForTypes(Iterable<Type> types);
  EntityComposition componentsForArchetype(Archetype archetype);
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
    for (var entry in _componentArrayFactories.entries) {
      _componentArrays[entry.key] = entry.value();
    }
  }

  SparseList<Component>? _getComponentArray(Type type) =>
      _componentArrays[type];

  @override
  EntityComposition componentsForTypes(Iterable<Type> types) {
    final entries =
        _componentArrays.entries.where((entry) => types.contains(entry.key));
    return EntityComposition(Map.fromEntries(entries));
  }

  @override
  EntityComposition componentsForArchetype(
    Archetype archetype,
  ) {
    final types = _archetypeManager.getComponentTypes(archetype);
    return componentsForTypes(types);
  }

  @override
  T? getComponent<T extends Component>(Entity entity) {
    final component = getComponentByType(T, entity);
    if (component is T) {
      return component;
    }
    return null;
  }

  @override
  Iterable<Component> getComponents(Entity entity) sync* {
    for (var componentArray in _componentArrays.values) {
      final component = componentArray[entity];
      if (component != null) yield component;
    }
  }

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

  @override
  bool hasComponentByType(Entity entity, Type type) =>
      _getComponentArray(type)?[entity] != null;

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

class EntityComposition implements Map<Type, SparseList<Component>> {
  final Map<Type, SparseList<Component>> _map;

  EntityComposition(this._map);

  T? get<T extends Component>(Entity entity) => _map[T]?[entity] as T?;

  SparseList<Component>? listFor<T extends Component>() => _map[T];

  @Deprecated('Use get<T>(entity) instead of [Type]?[entity] as T?')
  SparseList<Component>? getComponentList(Type type) => _map[type];

  @override
  SparseList<Component>? operator [](Object? key) => _map[key];

  @override
  void operator []=(Type key, SparseList<Component> value) => _map[key] = value;

  @override
  void clear() => _map.clear();

  @override
  Iterable<Type> get keys => _map.keys;

  @override
  SparseList<Component>? remove(Object? key) => _map.remove(key);

  @override
  Iterable<SparseList<Component>> get values => _map.values;

  @override
  void addAll(Map<Type, SparseList<Component>> other) => _map.addAll(other);

  @override
  void addEntries(Iterable<MapEntry<Type, SparseList<Component>>> newEntries) =>
      _map.addEntries(newEntries);

  @override
  Map<RK, RV> cast<RK, RV>() => _map.cast<RK, RV>();

  @override
  bool containsKey(Object? key) => _map.containsKey(key);

  @override
  bool containsValue(Object? value) => _map.containsValue(value);

  @override
  Iterable<MapEntry<Type, SparseList<Component>>> get entries => _map.entries;

  @override
  void forEach(void Function(Type key, SparseList<Component> value) action) =>
      _map.forEach(action);

  @override
  bool get isEmpty => _map.isEmpty;

  @override
  bool get isNotEmpty => _map.isNotEmpty;

  @override
  int get length => _map.length;

  @override
  Map<K2, V2> map<K2, V2>(
          MapEntry<K2, V2> Function(Type key, SparseList<Component> value)
              convert) =>
      _map.map(convert);

  @override
  SparseList<Component> putIfAbsent(
          Type key, SparseList<Component> Function() ifAbsent) =>
      _map.putIfAbsent(key, ifAbsent);

  @override
  void removeWhere(bool Function(Type key, SparseList<Component> value) test) =>
      _map.removeWhere(test);

  @override
  SparseList<Component> update(Type key,
          SparseList<Component> Function(SparseList<Component> value) update,
          {SparseList<Component> Function()? ifAbsent}) =>
      _map.update(key, update, ifAbsent: ifAbsent);

  @override
  void updateAll(SparseList<Component> Function(
          Type key, SparseList<Component> value)
      update) => _map.updateAll(update);
}
