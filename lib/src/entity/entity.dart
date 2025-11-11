import 'package:dentity/dentity.dart';

typedef Entity = int;

abstract class EntityManagerListener {
  void onEntityCreated(Entity entity);
  void onEntityWillDestroy(Entity entity);
  void onEntityArchetypeChanged(
    Entity entity,
    Archetype newArchetype,
    Archetype oldArchetype,
  );
}

class EntityManager implements EntityManagerListener {
  final Map<Entity, Archetype> _entityByArchetype = {};
  final Map<Archetype, Set<Entity>> _entitiesByArchetype = {};

  Entity _newEntity = 0;
  ComponentManager get componentManager => _componentManager;
  final ComponentManager _componentManager;
  final ArchetypeManagerInterface _archetypeManager;
  final Map<Archetype, Set<Entity>> _recycleBin = {};
  final List<EntityManagerListener> _observers = [];
  final Set<Entity> _deletionQueue = {};
  final List<(Entity, Iterable<Component>)> _creationQueue = [];
  EntityStats? _entityStats;
  ArchetypeStats? _archetypeStats;
  final Map<Archetype, EntityView> _viewCache = {};

  Iterable<Entity> get entities =>
      _entitiesByArchetype.entries.map((e) => e.value).expand((e) => e);

  EntityManager(this._componentManager)
      : _archetypeManager = _componentManager.archetypeManager;

  void setStats(EntityStats? entityStats, ArchetypeStats? archetypeStats) {
    _entityStats = entityStats;
    _archetypeStats = archetypeStats;
  }

  void updateArchetypeStats() {
    if (_archetypeStats == null) return;
    for (final entry in _entitiesByArchetype.entries) {
      _archetypeStats!.updateEntityCount(entry.key, entry.value.length);
    }
    for (final entry in _recycleBin.entries) {
      _archetypeStats!.updateRecycleBinSize(entry.key, entry.value.length);
    }
  }

  Entity createEntity(Iterable<Component> components) {
    final archetype = _archetypeManager.getArchetype(
      components.map((c) => c.runtimeType),
    );
    final recycleBin = _recycleBin.putIfAbsent(archetype, () => {});
    final recycled = recycleBin.isEmpty ? null : recycleBin.first;

    final entity = recycled ?? _newEntity++;
    if (recycled != null) {
      recycleBin.remove(recycled);
      _entityStats?.incrementRecycled();
    }

    _creationQueue.add((entity, components));
    _entityStats?.updateCreationQueueSize(_creationQueue.length);
    return entity;
  }

  void processCreationQueue() {
    for (final (entity, components) in _creationQueue) {
      _createEntityImmediate(entity, components);
    }
    _creationQueue.clear();
    _entityStats?.updateCreationQueueSize(0);
  }

  void _createEntityImmediate(Entity entity, Iterable<Component> components) {
    _componentManager.addComponents(entity, components);
    final archetype = _archetypeManager.getArchetype(
      components.map((c) => c.runtimeType),
    );
    _updateEntityArchetype(entity, archetype);
    onEntityCreated(entity);
    _entityStats?.incrementCreated();
  }

  Entity cloneEntity(Entity entity) {
    final components =
        _componentManager.getComponents(entity).map((c) => c.clone());
    return createEntity(components);
  }

  bool hasEntity(Entity entity) => _entityByArchetype.containsKey(entity);

  void destroyEntity(Entity entity) {
    _deletionQueue.add(entity);
    _entityStats?.updateDeletionQueueSize(_deletionQueue.length);
  }

  void processDeletionQueue() {
    for (final entity in _deletionQueue) {
      _destroyEntityImmediate(entity);
    }
    _deletionQueue.clear();
    _entityStats?.updateDeletionQueueSize(0);
  }

  void _destroyEntityImmediate(Entity entity) {
    final archetype = getArchetype(entity);
    if (archetype == null) return;
    onEntityWillDestroy(entity);
    _recycleBin.putIfAbsent(archetype, () => {}).add(entity);
    _componentManager.removeAllComponents(entity);
    _entitiesByArchetype[archetype]?.remove(entity);
    _entityByArchetype.remove(entity);
    _entityStats?.incrementDestroyed();
  }

  void addComponents(Entity entity, Iterable<Component> components) {
    _componentManager.addComponents(entity, components);
    final newArchetype = _archetypeManager.getArchetype(
      components.map((c) => c.runtimeType),
    );
    _updateEntityArchetype(entity, newArchetype);
  }

  void removeComponents(Entity entity, Iterable<Type> componentTypes) {
    final currentArchetype = getArchetype(entity);
    if (currentArchetype == null) return;

    final currentComponents =
        _archetypeManager.getComponentTypes(currentArchetype);

    _componentManager.removeComponentsByType(entity, componentTypes);
    final newArchetype = _archetypeManager.getArchetype(
      currentComponents.where((c) => !componentTypes.contains(c)),
    );

    _updateEntityArchetype(entity, newArchetype);
  }

  Archetype? getArchetype(Entity entity) => _entityByArchetype[entity];

  Iterable<Entity> getEntitiesWithComponents(Set<Type> types) {
    final archetype = _archetypeManager.getArchetype(types);
    return getEntitiesMatching(archetype);
  }

  Iterable<Entity> getEntitiesMatching(Archetype archetype) {
    return _entitiesByArchetype.entries
        .where((e) => _archetypeManager.isSubtype(e.key, archetype))
        .expand((e) => e.value);
  }

  EntityView getOrCreateView(Archetype archetype) {
    return _viewCache.putIfAbsent(
      archetype,
      () => EntityView(this, archetype),
    );
  }

  void clearViewCache() {
    _viewCache.clear();
  }

  int get viewCacheSize => _viewCache.length;

  void _updateEntityArchetype(Entity entity, Archetype newArchetype) {
    final previousArchetype = getArchetype(entity);
    _entityByArchetype[entity] = newArchetype;
    if (previousArchetype != newArchetype) {
      _entitiesByArchetype.putIfAbsent(newArchetype, () => {}).add(entity);
      _entitiesByArchetype[previousArchetype]?.remove(entity);
      if (previousArchetype != null) {
        onEntityArchetypeChanged(entity, newArchetype, previousArchetype);
      }
    }
  }

  void addObserver(EntityManagerListener observer) {
    _observers.add(observer);
  }

  void removeObserver(EntityManagerListener observer) {
    _observers.remove(observer);
  }

  @override
  void onEntityCreated(Entity entity) {
    for (var observer in _observers) {
      observer.onEntityCreated(entity);
    }
  }

  @override
  void onEntityWillDestroy(Entity entity) {
    for (var observer in _observers) {
      observer.onEntityWillDestroy(entity);
    }
  }

  @override
  void onEntityArchetypeChanged(
    Entity entity,
    Archetype newArchetype,
    Archetype oldArchetype,
  ) {
    for (var observer in _observers) {
      observer.onEntityArchetypeChanged(entity, newArchetype, oldArchetype);
    }
  }
}
