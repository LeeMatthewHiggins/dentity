import 'package:dentity/dentity.dart';

typedef Entity = int;

class EntityManager {
  final Map<Entity, Archetype> _entityByArchetype = {};
  final Map<Archetype, Set<Entity>> _entitiesByArchetype = {};

  Entity _newEntity = 0;
  ComponentManager get componentManager => _componentManager;
  final ComponentManager _componentManager;
  final ArchetypeManagerIterface _archetypeManager;

  final Map<Archetype, Set<Entity>> _recycleBin = {};

  Iterable<Entity> get entities =>
      _entitiesByArchetype.entries.map((e) => e.value).expand((e) => e);

  EntityManager(this._componentManager)
      : _archetypeManager = _componentManager.archetypeManager;

  Entity createEntity(Iterable<Component> components) {
    final archetype = _archetypeManager.getArchetype(
      components.map((c) => c.runtimeType),
    );
    final recycleBin = _recycleBin.putIfAbsent(archetype, () => {});
    final recycled = recycleBin.firstOrNull;
    if (recycled != null) {
      _componentManager.addComponents(recycled, components);
      recycleBin.remove(recycled);
      return recycled;
    }
    _componentManager.addComponents(_newEntity, components);
    final newArhcetype = _archetypeManager.getArchetype(
      components.map((c) => c.runtimeType),
    );
    _updateAchetype(_newEntity, newArhcetype);
    return _newEntity++;
  }

  bool hasEntity(Entity entity) {
    return _entityByArchetype.containsKey(entity);
  }

  void destroyEntity(Entity entity) {
    final archetype = getArchetype(entity);
    if (archetype == null) {
      return;
    }
    _recycleBin.putIfAbsent(archetype, () => {}).add(entity);
    _componentManager.removeAllComponents(entity);
    _entitiesByArchetype[getArchetype(entity)]?.remove(entity);
    _entityByArchetype.remove(entity);
  }

  void addComponents(Entity entity, Iterable<Component> components) {
    _componentManager.addComponents(entity, components);
    final newArhcetype = _archetypeManager.getArchetype(
      components.map((c) => c.runtimeType),
    );
    _updateAchetype(entity, newArhcetype);
  }

  void removeComponents(Entity entity, Iterable<Type> componentTypes) {
    final currentArchetype = getArchetype(entity);
    if (currentArchetype == null) {
      return;
    }
    final currentComponents =
        _archetypeManager.getComponentTypes(currentArchetype);

    _componentManager.removeComponentsByType(entity, componentTypes);
    final newArhcetype = _archetypeManager.getArchetype(
      currentComponents.where((c) => !componentTypes.contains(c)),
    );

    _updateAchetype(entity, newArhcetype);
  }

  Archetype? getArchetype(Entity entity) {
    return _entityByArchetype[entity];
  }

  Iterable<Entity> _getEntitiesMatchingSubArchetypes(Archetype archetype) {
    return _entitiesByArchetype.entries
        .where((e) => _archetypeManager.isSubtype(e.key, archetype))
        .expand((e) => e.value);
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

class EntityView implements Iterable<Entity> {
  final EntityManager _entityManager;
  final Archetype archetype;
  final Map<Type, SparseList<Component>> _componentArrays;
  Map<Type, SparseList<Component>> get componentArrays => _componentArrays;

  EntityView(this._entityManager, this.archetype)
      : _componentArrays =
            _entityManager.componentManager.componentsForArchetype(
          archetype,
        );

  factory EntityView.fromTypes(
    EntityManager entityManager,
    Set<Type> componentTypes,
  ) {
    final archetype = entityManager.componentManager.archetypeManager
        .getArchetype(componentTypes);
    return EntityView(entityManager, archetype);
  }

  Iterable<Entity> get _entities =>
      _entityManager._getEntitiesMatchingSubArchetypes(archetype);

  SparseList<Component>? getComponentArray(Type type) {
    return _componentArrays[type];
  }

  Component? getComponentForType(Type type, Entity entity) {
    return _componentArrays[type]?[entity];
  }

  T? getComponent<T>(Entity entity) {
    return _componentArrays[T]?[entity] as T?;
  }

  @override
  Iterator<Entity> get iterator => _entities.iterator;

  @override
  int get length => _entities.length;

  @override
  bool any(bool Function(Entity entity) test) => _entities.any(test);

  @override
  bool contains(Object? element) => _entities.contains(element);

  @override
  Entity elementAt(int index) => _entities.elementAt(index);

  @override
  bool every(bool Function(Entity entity) test) => _entities.every(test);

  @override
  Iterable<R> expand<R>(Iterable<R> Function(Entity entity) toElements) =>
      _entities.expand(toElements);

  @override
  Entity get first => _entities.first;

  @override
  Entity firstWhere(bool Function(Entity entity) test,
          {Entity Function()? orElse}) =>
      _entities.firstWhere(test, orElse: orElse);

  @override
  T fold<T>(
          T initialValue, T Function(T previousValue, Entity entity) combine) =>
      _entities.fold(initialValue, combine);

  @override
  Iterable<Entity> followedBy(Iterable<Entity> other) =>
      _entities.followedBy(other);

  @override
  void forEach(void Function(Entity entity) f) => _entities.forEach(f);

  @override
  Iterable<Entity> cast<Entity>() => _entities.cast<Entity>();

  @override
  Entity get last => _entities.last;

  @override
  Entity lastWhere(bool Function(Entity entity) test,
          {Entity Function()? orElse}) =>
      _entities.lastWhere(test, orElse: orElse);

  @override
  Iterable<R> map<R>(R Function(Entity entity) f) => _entities.map(f);

  @override
  Entity reduce(Entity Function(Entity value, Entity element) combine) =>
      _entities.reduce(combine);

  @override
  Iterable<Entity> skip(int count) => _entities.skip(count);

  @override
  Iterable<Entity> skipWhile(bool Function(Entity value) test) =>
      _entities.skipWhile(test);

  @override
  Iterable<Entity> take(int count) => _entities.take(count);

  @override
  Iterable<Entity> takeWhile(bool Function(Entity value) test) =>
      _entities.takeWhile(test);

  @override
  List<Entity> toList({bool growable = true}) =>
      _entities.toList(growable: growable);

  @override
  Set<Entity> toSet() => _entities.toSet();

  @override
  Iterable<Entity> where(bool Function(Entity entity) test) =>
      _entities.where(test);

  @override
  Iterable<T> whereType<T>() => _entities.whereType<T>();

  @override
  String join([String separator = '']) => _entities.join(separator);

  @override
  bool get isEmpty => _entities.isEmpty;

  @override
  bool get isNotEmpty => _entities.isNotEmpty;

  @override
  Entity get single => _entities.single;

  @override
  Entity singleWhere(bool Function(Entity element) test,
          {Entity Function()? orElse}) =>
      _entities.singleWhere(test, orElse: orElse);
}

extension EntityViewOnEntityManager on EntityManager {
  EntityView view(Archetype archetype) {
    return EntityView(this, archetype);
  }

  EntityView viewForTypes(Set<Type> types) {
    return EntityView.fromTypes(this, types);
  }
}
