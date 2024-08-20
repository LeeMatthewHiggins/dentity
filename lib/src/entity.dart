import 'package:dentity/dentity.dart';
import 'package:dentity/src/archetype.dart';
import 'package:dentity/src/dentity_base.dart';

typedef Entity = int;

class EntityManager {
  final Map<Entity, Archetype> _entityByArchetype = {};
  final Map<Archetype, Set<Entity>> _entitiesByArchetype = {};

  Entity _newEntity = 0;
  ComponentManager get componentManager => _componentManager;
  final ComponentManager _componentManager;
  final ArchetypeManager _archetypeManager;

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

  void removeEntity(Entity entity) {
    final archetype = getArchetype(entity);
    if (archetype == null) {
      return;
    }
    _recycleBin.putIfAbsent(archetype, () => {}).add(entity);
    _componentManager.removeAllComponents(entity);
    _entitiesByArchetype[getArchetype(entity)]?.remove(entity);
    _entityByArchetype.remove(entity);
  }

  T? getComponent<T extends Component>(Entity entity) {
    return _componentManager.getComponent<T>(entity);
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

  Iterable<Entity> getEntitiesForArchetype(Archetype archetype) {
    return _entitiesByArchetype[archetype] ?? {};
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

class View {
  final EntityManager entityManager;
  final Archetype archetype;

  View(this.entityManager, this.archetype);

  Iterable<Entity> get entities =>
      entityManager.getEntitiesForArchetype(archetype);

  T? getComponent<T extends Component>(Entity entity) {
    return entityManager.getComponent<T>(entity);
  }

  void addComponents(Entity entity, Iterable<Component> components) {
    entityManager.addComponents(entity, components);
  }

  void removeComponents(Entity entity, Iterable<Type> componentTypes) {
    entityManager.removeComponents(entity, componentTypes);
  }

  void removeEntity(Entity entity) {
    entityManager.removeEntity(entity);
  }
}
