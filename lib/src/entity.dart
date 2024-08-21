import 'package:dentity/dentity.dart';

typedef Entity = int;

class EntityManager {
  final Map<Entity, Archetype> _entityByArchetype = {};
  final Map<Archetype, Set<Entity>> _entitiesByArchetype = {};

  Entity _newEntity = 0;
  ComponentManager get componentManager => _componentManager;
  final ComponentManager _componentManager;
  final ArchetypeManagerInterface _archetypeManager;

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
    final recycled = recycleBin.isEmpty ? null : recycleBin.first;
    if (recycled != null) {
      _componentManager.addComponents(recycled, components);
      recycleBin.remove(recycled);
      return recycled;
    }
    _componentManager.addComponents(_newEntity, components);
    _updateEntityArchetype(_newEntity, archetype);
    return _newEntity++;
  }

  Entity cloneEntity(Entity entity) {
    final components =
        _componentManager.getComponents(entity).map((c) => c.clone());
    return createEntity(components);
  }

  bool hasEntity(Entity entity) => _entityByArchetype.containsKey(entity);

  void destroyEntity(Entity entity) {
    final archetype = getArchetype(entity);
    if (archetype == null) return;

    _recycleBin.putIfAbsent(archetype, () => {}).add(entity);
    _componentManager.removeAllComponents(entity);
    _entitiesByArchetype[archetype]?.remove(entity);
    _entityByArchetype.remove(entity);
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

  void _updateEntityArchetype(Entity entity, Archetype newArchetype) {
    final previousArchetype = getArchetype(entity);
    _entityByArchetype[entity] = newArchetype;
    if (previousArchetype != newArchetype) {
      _entitiesByArchetype.putIfAbsent(newArchetype, () => {}).add(entity);
      _entitiesByArchetype[previousArchetype]?.remove(entity);
    }
  }
}
