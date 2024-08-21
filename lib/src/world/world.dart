import 'package:dentity/dentity.dart';

class World {
  EntityManager get entityManager => _entityManager;
  final EntityManager _entityManager;
  final ComponentManager _componentManager;
  final List<EntitySystem> _systems;

  World(
    this._componentManager,
    this._entityManager,
    this._systems,
  ) {
    for (var system in _systems) {
      system.attach(_entityManager);
    }
  }

  void process({Duration delta = const Duration(milliseconds: 16)}) {
    for (var system in _systems) {
      system.process(delta);
    }
  }

  int createEntity(Iterable<Component> components) =>
      _entityManager.createEntity(components);

  T? getComponent<T extends Component>(Entity entity) =>
      _componentManager.getComponent<T>(entity);

  void addComponents(Entity entity, Iterable<Component> components) =>
      _entityManager.addComponents(entity, components);
  void removeComponents(Entity entity, Iterable<Type> componentTypes) =>
      _entityManager.removeComponents(entity, componentTypes);
  void destroyEntity(Entity entity) => _entityManager.destroyEntity(entity);
}

extension EntityViewOnWorld on World {
  EntityView view(Archetype archetype) => EntityView(_entityManager, archetype);
  EntityView viewForTypes(Set<Type> types) =>
      EntityView.fromTypes(_entityManager, types);
}
