import 'package:dentity/dentity.dart';

class World {
  EntityManager get entityManager => _entityManager;
  final EntityManager _entityManager;
  final ComponentManager _componentManager;
  final List<System> _systems;
  final WorldStats? stats;

  World(
    this._componentManager,
    this._entityManager,
    this._systems, {
    bool enableStats = false,
  }) : stats = enableStats ? WorldStats() : null {
    final worldStats = stats;
    if (worldStats != null) {
      _entityManager.setStats(worldStats.entities, worldStats.archetypes);
    }
    for (var system in _systems) {
      system.attach(_entityManager);
    }
  }

  void process({Duration delta = const Duration(milliseconds: 16)}) {
    _entityManager.processCreationQueue();

    for (var system in _systems) {
      if (stats != null) {
        final systemStats = stats!.getOrCreateSystemStats(system.runtimeType.toString());
        final stopwatch = Stopwatch()..start();
        final entitiesBefore = _entityManager.entities.length;

        system.process(delta);

        stopwatch.stop();
        systemStats.recordExecution(stopwatch.elapsed, entitiesBefore);
      } else {
        system.process(delta);
      }

      _entityManager.processDeletionQueue();
    }

    if (stats != null) {
      _entityManager.updateArchetypeStats();
      stats!.incrementFrameCount();
    }
  }

  int createEntity(Iterable<Component> components) =>
      _entityManager.createEntity(components);

  T? getComponent<T extends Component>(Entity entity) =>
      _componentManager.getComponent<T>(entity);

  int cloneEntity(Entity entity) => _entityManager.cloneEntity(entity);

  void addComponents(Entity entity, Iterable<Component> components) =>
      _entityManager.addComponents(entity, components);
  void removeComponents(Entity entity, Iterable<Type> componentTypes) =>
      _entityManager.removeComponents(entity, componentTypes);
  void destroyEntity(Entity entity) => _entityManager.destroyEntity(entity);

  T? getSystem<T extends System>() =>
      _systems.firstWhere((system) => system is T) as T?;
}

extension EntityViewOnWorld on World {
  EntityView view(Archetype archetype) => EntityView(_entityManager, archetype);
  EntityView viewForTypes(Set<Type> types) =>
      EntityView.fromTypes(_entityManager, types);
}
